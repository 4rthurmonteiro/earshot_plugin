package dev.earshot.capture

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioRecordingConfiguration
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Captures float32 mono PCM with [AudioRecord] on a background thread.
 *
 * Every callback runs on the main thread. Interruptions are reported through
 * [onState]: when the system silences this app's capture (a phone call on
 * Android 10+), chunks stop until it is unsilenced. When the recorder dies
 * (for example, the audio server restarted), capture is recreated with
 * retries, and [onError] is called only if every retry fails.
 *
 * Audio focus is deliberately not requested: it is a playback concept, and
 * requesting it would pause the user's music.
 */
internal class AudioCapture(
    private val context: Context,
    private val onChunk: (samples: ByteArray, timestampMicros: Long) -> Unit,
    private val onState: (CaptureStateMessage) -> Unit,
    private val onError: (code: String, message: String) -> Unit,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(AudioManager::class.java)

    private var sampleRate = 0
    private var record: AudioRecord? = null
    private var thread: Thread? = null
    private var recordingCallback: AudioManager.AudioRecordingCallback? = null

    /** Incremented on every (re)start and stop, to drop stale posts. */
    private var generation = 0
    private var startNanos = 0L
    private var retries = 0
    private var state = CaptureStateMessage.IDLE

    @Volatile
    private var silenced = false

    /** Opens the microphone at [sampleRate] Hz. Throws a [FlutterError] on failure. */
    fun start(sampleRate: Int) {
        stop()
        if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw FlutterError("permissionDenied", "RECORD_AUDIO has not been granted.", null)
        }
        this.sampleRate = sampleRate
        startNanos = SystemClock.elapsedRealtimeNanos()
        retries = 0
        val error = open(baseMicros = 0L)
        if (error != null) {
            throw FlutterError("audioUnavailable", error, null)
        }
        setState(CaptureStateMessage.CAPTURING)
    }

    /** Closes the microphone. Safe to call when not running. */
    fun stop() {
        generation++
        mainHandler.removeCallbacksAndMessages(null)
        close()
        setState(CaptureStateMessage.IDLE)
    }

    /** Opens a recorder and its reader thread. Returns an error message on failure. */
    @SuppressLint("MissingPermission") // Checked in start().
    private fun open(baseMicros: Long): String? {
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_FLOAT,
        )
        if (minBuffer <= 0) {
            return "The device cannot record float PCM at $sampleRate Hz."
        }
        // Keep at least 200 ms of headroom so the reader never overruns.
        val bufferBytes = maxOf(minBuffer, sampleRate * FLOAT_BYTES / 5)

        var created: AudioRecord? = null
        for (source in audioSources()) {
            val candidate = try {
                AudioRecord(
                    source,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_FLOAT,
                    bufferBytes,
                )
            } catch (e: IllegalArgumentException) {
                null
            }
            if (candidate?.state == AudioRecord.STATE_INITIALIZED) {
                created = candidate
                break
            }
            candidate?.release()
        }
        val newRecord = created ?: return "The microphone could not be opened."

        try {
            newRecord.startRecording()
        } catch (e: IllegalStateException) {
            newRecord.release()
            return "The microphone could not be started: ${e.message}"
        }
        if (newRecord.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            newRecord.release()
            return "The microphone is in use by another app."
        }

        record = newRecord
        silenced = false
        registerRecordingCallback(newRecord)
        val readerGeneration = generation
        thread = Thread({ read(newRecord, readerGeneration, baseMicros) }, "earshot-capture").apply {
            priority = Thread.MAX_PRIORITY
            start()
        }
        return null
    }

    private fun close() {
        recordingCallback?.let { audioManager.unregisterAudioRecordingCallback(it) }
        recordingCallback = null
        val oldRecord = record ?: return
        record = null
        try {
            // Unblocks the reader thread's read().
            oldRecord.stop()
        } catch (e: IllegalStateException) {
            // Already stopped.
        }
        thread?.join(JOIN_TIMEOUT_MS)
        thread = null
        oldRecord.release()
    }

    /** UNPROCESSED when the device supports it, with VOICE_RECOGNITION as the fallback. */
    private fun audioSources(): List<Int> {
        val unprocessed = audioManager.getProperty(
            AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED,
        ) == "true"
        return if (unprocessed) {
            listOf(MediaRecorder.AudioSource.UNPROCESSED, MediaRecorder.AudioSource.VOICE_RECOGNITION)
        } else {
            listOf(MediaRecorder.AudioSource.VOICE_RECOGNITION)
        }
    }

    /** Runs on the reader thread until the recorder stops or fails. */
    private fun read(record: AudioRecord, readerGeneration: Int, baseMicros: Long) {
        val buffer = FloatArray(maxOf(sampleRate / CHUNKS_PER_SECOND, 1))
        var frames = 0L
        while (true) {
            val read = record.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)
            if (read < 0) {
                mainHandler.post { if (readerGeneration == generation) recover(read) }
                return
            }
            if (read == 0) {
                // Stopped, or nothing yet.
                if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) return
                continue
            }
            val timestampMicros = baseMicros + frames * MICROS_PER_SECOND / sampleRate
            frames += read
            // Silenced capture delivers zeros, which would distort levels.
            if (silenced) continue
            val bytes = ByteBuffer.allocate(read * FLOAT_BYTES).order(ByteOrder.LITTLE_ENDIAN)
            bytes.asFloatBuffer().put(buffer, 0, read)
            val samples = bytes.array()
            mainHandler.post { if (readerGeneration == generation) onChunk(samples, timestampMicros) }
        }
    }

    /** The recorder failed with [code]: report an interruption and recreate it. */
    private fun recover(code: Int) {
        setState(CaptureStateMessage.INTERRUPTED)
        close()
        if (retries >= MAX_RETRIES) {
            val message = "The microphone stopped (AudioRecord error $code) and could not be reopened."
            stop()
            onError("audioUnavailable", message)
            return
        }
        retries++
        val retryGeneration = ++generation
        mainHandler.postDelayed({
            if (retryGeneration != generation) return@postDelayed
            val elapsedMicros = (SystemClock.elapsedRealtimeNanos() - startNanos) / NANOS_PER_MICRO
            if (open(baseMicros = elapsedMicros) == null) {
                retries = 0
                setState(CaptureStateMessage.CAPTURING)
            } else {
                recover(code)
            }
        }, RETRY_DELAY_MS)
    }

    private fun registerRecordingCallback(record: AudioRecord) {
        // isClientSilenced() exists from Android 10, which is also when the
        // system started silencing capture instead of failing it.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val sessionId = record.audioSessionId
        val callback = object : AudioManager.AudioRecordingCallback() {
            override fun onRecordingConfigChanged(configs: List<AudioRecordingConfiguration>) {
                val config = configs.firstOrNull { it.clientAudioSessionId == sessionId } ?: return
                onSilencedChanged(config.isClientSilenced)
            }
        }
        audioManager.registerAudioRecordingCallback(callback, mainHandler)
        recordingCallback = callback
    }

    private fun onSilencedChanged(isSilenced: Boolean) {
        if (isSilenced == silenced || record == null) return
        silenced = isSilenced
        setState(if (isSilenced) CaptureStateMessage.INTERRUPTED else CaptureStateMessage.CAPTURING)
    }

    private fun setState(newState: CaptureStateMessage) {
        if (newState == state) return
        state = newState
        onState(newState)
    }

    private companion object {
        const val FLOAT_BYTES = 4
        const val CHUNKS_PER_SECOND = 20
        const val MICROS_PER_SECOND = 1_000_000L
        const val NANOS_PER_MICRO = 1_000L
        const val MAX_RETRIES = 10
        const val RETRY_DELAY_MS = 500L
        const val JOIN_TIMEOUT_MS = 500L
    }
}
