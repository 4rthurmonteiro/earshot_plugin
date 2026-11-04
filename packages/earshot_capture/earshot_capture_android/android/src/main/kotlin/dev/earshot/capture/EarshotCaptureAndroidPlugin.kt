package dev.earshot.capture

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/** The Android host side of earshot_capture. */
class EarshotCaptureAndroidPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    EarshotCaptureHostApi {
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var capture: AudioCapture? = null
    private var pcmSink: PigeonEventSink<PcmChunkMessage>? = null
    private var stateSink: PigeonEventSink<CaptureStateEventMessage>? = null
    private val pendingPermissionRequests = mutableListOf<Continuation<PermissionStatusMessage>>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val appContext = binding.applicationContext
        context = appContext
        capture = AudioCapture(
            context = appContext,
            onChunk = { samples, timestampMicros ->
                pcmSink?.success(PcmChunkMessage(samples, timestampMicros))
            },
            onState = { state -> stateSink?.success(CaptureStateEventMessage(state)) },
            onError = { code, message -> pcmSink?.error(code, message, null) },
        )
        EarshotCaptureHostApi.setUp(binding.binaryMessenger, this)
        PcmChunksStreamHandler.register(
            binding.binaryMessenger,
            object : PcmChunksStreamHandler() {
                override fun onListen(p0: Any?, sink: PigeonEventSink<PcmChunkMessage>) {
                    pcmSink = sink
                }

                override fun onCancel(p0: Any?) {
                    pcmSink = null
                }
            },
        )
        CaptureStatesStreamHandler.register(
            binding.binaryMessenger,
            object : CaptureStatesStreamHandler() {
                override fun onListen(p0: Any?, sink: PigeonEventSink<CaptureStateEventMessage>) {
                    stateSink = sink
                }

                override fun onCancel(p0: Any?) {
                    stateSink = null
                }
            },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        capture?.stop()
        capture = null
        EarshotCaptureHostApi.setUp(binding.binaryMessenger, null)
        PcmChunksEventChannel(binding.binaryMessenger).setStreamHandler(null)
        CaptureStatesEventChannel(binding.binaryMessenger).setStreamHandler(null)
        pcmSink = null
        stateSink = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        // The result will never arrive: answer with the status as it stands.
        if (pendingPermissionRequests.isNotEmpty()) {
            val status = microphonePermissionStatus()
            val requests = pendingPermissionRequests.toList()
            pendingPermissionRequests.clear()
            requests.forEach { it.resume(status) }
        }
    }

    /**
     * Reads RECORD_AUDIO without prompting. Android cannot tell "never asked"
     * apart from "denied" without an Activity, so this is granted or denied.
     */
    override fun microphonePermissionStatus(): PermissionStatusMessage {
        val ctx = checkNotNull(context) { "earshot_capture is not attached to an engine" }
        // minSdk is 24, so Context.checkSelfPermission (API 23) needs no androidx.
        val result = ctx.checkSelfPermission(Manifest.permission.RECORD_AUDIO)
        return if (result == PackageManager.PERMISSION_GRANTED) {
            PermissionStatusMessage.GRANTED
        } else {
            PermissionStatusMessage.DENIED
        }
    }

    /** Asks for RECORD_AUDIO through the foreground Activity. */
    override suspend fun requestMicrophonePermission(): PermissionStatusMessage {
        if (microphonePermissionStatus() == PermissionStatusMessage.GRANTED) {
            return PermissionStatusMessage.GRANTED
        }
        val activity: Activity = activityBinding?.activity
            ?: throw FlutterError(
                "noActivity",
                "Requesting the microphone permission needs a foreground Activity.",
                null,
            )
        return suspendCoroutine { continuation ->
            pendingPermissionRequests.add(continuation)
            // Concurrent requests share the single system dialog.
            if (pendingPermissionRequests.size == 1) {
                activity.requestPermissions(
                    arrayOf(Manifest.permission.RECORD_AUDIO),
                    PERMISSION_REQUEST_CODE,
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        // An empty result means the request was interrupted; read the real status.
        val status = when {
            grantResults.isEmpty() -> microphonePermissionStatus()
            grantResults[0] == PackageManager.PERMISSION_GRANTED -> PermissionStatusMessage.GRANTED
            else -> PermissionStatusMessage.DENIED
        }
        val requests = pendingPermissionRequests.toList()
        pendingPermissionRequests.clear()
        requests.forEach { it.resume(status) }
        return true
    }

    override fun startCapture(config: CaptureConfigMessage) {
        val capture = checkNotNull(capture) { "earshot_capture is not attached to an engine" }
        capture.start(config.sampleRateHz.toInt())
    }

    override fun stopCapture() {
        capture?.stop()
    }

    private companion object {
        /** Arbitrary, but unique enough not to collide with the app's own requests. */
        const val PERMISSION_REQUEST_CODE = 0x6561
    }
}
