import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier_darwin/src/messages.g.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens a PCM stream with a capture configuration.
typedef PcmOpener = Stream<PcmChunk> Function(CaptureConfig config);

/// {@template earshot_classifier_darwin}
/// The iOS and macOS implementation of [EarshotClassifierPlatform], backed by
/// the [ClassifierBackend.apple] backend: Apple's on-device SoundAnalysis
/// framework (`SNClassifySoundRequest`, classifier version 1).
///
/// Requires iOS 15 or macOS 12. SoundAnalysis classifies PCM captured by
/// `earshot_capture`, so it shares the one microphone session of the app.
/// Classification never prompts for the microphone permission: request it
/// first, for example with `EarshotCapture.requestMicrophonePermission`.
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including smoke and carbon monoxide alarms.
/// {@endtemplate}
class EarshotClassifierDarwin extends EarshotClassifierPlatform {
  /// {@macro earshot_classifier_darwin}
  ///
  /// Tests can pass the Pigeon host API, the native event stream and the
  /// capture stream that [detections] classifies.
  new({
    @visibleForTesting EarshotClassifierHostApi? hostApi,
    @visibleForTesting this._eventMessages,
    @visibleForTesting PcmOpener? openPcm,
  }) : _hostApi = hostApi ?? EarshotClassifierHostApi(),
       // Looked up on each call: earshot_capture may register its
       // implementation after this one.
       _openPcm =
           openPcm ?? ((config) => EarshotCapturePlatform.instance.pcm(config));

  final EarshotClassifierHostApi _hostApi;
  final Stream<ClassifierEventMessage>? _eventMessages;
  final PcmOpener _openPcm;

  // One Dart stream for the event channel, shared by every session: a second
  // `receiveBroadcastStream()` on the same channel would steal the first
  // one's messages. Events carry the session id they belong to.
  late final Stream<ClassifierEventMessage> _events =
      _eventMessages ?? classifierEvents();

  int _nextSessionId = 0;

  /// Registers this class as the [EarshotClassifierPlatform.instance].
  static void registerWith() {
    EarshotClassifierPlatform.instance = EarshotClassifierDarwin();
  }

  /// Whether SoundAnalysis can classify on this device. Never prompts the
  /// user.
  @override
  Future<bool> isAvailable() => _hostApi.isAvailable();

  /// Captures 16 kHz PCM with `earshot_capture` and classifies it with
  /// SoundAnalysis, as [classify] does.
  ///
  /// The capture subscription joins the app's microphone session, so it
  /// fails with [CaptureErrorCode.sampleRateConflict] while capture runs at
  /// another rate. Use [classify] to classify a capture stream at any rate.
  @override
  Stream<SoundDetection> detections(ClassifierConfig config) =>
      classify(_openPcm(const CaptureConfig()), config);

  /// Classifies [pcm] with SoundAnalysis.
  ///
  /// Each `listen()` starts its own session, with its own
  /// `SNAudioStreamAnalyzer`, and listens to [pcm]. Every chunk is copied to
  /// the host. Cancelling the subscription cancels the subscription to
  /// [pcm] and stops the session.
  ///
  /// SoundAnalysis accepts every [SampleRate]. It analyzes windows of about
  /// one second that overlap by half. Every label of a window at or above
  /// [ClassifierConfig.minConfidence] is reported, timestamped with the
  /// start of the window on the clock of the [PcmChunk.timestamp]s. After
  /// an interruption, the timestamps jump with the PCM.
  ///
  /// The first error ends the stream. Errors from [pcm], such as a
  /// [CaptureException], are forwarded unchanged. SoundAnalysis failures
  /// are delivered as a [CaptureException] with
  /// [CaptureErrorCode.unknown].
  @override
  Stream<SoundDetection> classify(
    Stream<PcmChunk> pcm,
    ClassifierConfig config,
  ) => Stream.multi((controller) {
    final sessionId = _nextSessionId++;
    var done = false;
    StreamSubscription<ClassifierEventMessage>? events;
    StreamSubscription<PcmChunk>? chunks;
    late final Future<bool> started;
    Future<void>? stopping;

    Future<void> stop() => stopping ??= () async {
      done = true;
      await Future.wait([?chunks?.cancel(), ?events?.cancel()]);
      // Waiting for the start means a stop never overtakes it.
      if (!await started) return;
      try {
        await _hostApi.stopSession(sessionId);
      } on Object {
        // The session is gone either way; nothing is listening anymore.
      }
    }();

    void end(Object? error, StackTrace? stackTrace) {
      if (done) return;
      done = true;
      if (error != null) controller.addErrorSync(error, stackTrace);
      controller.closeSync();
      unawaited(stop());
    }

    void fail(Object error, StackTrace? stackTrace) =>
        end(_toCaptureException(error), stackTrace);

    void onChunk(PcmChunk chunk) {
      final samples = chunk.samples;
      unawaited(
        _hostApi
            .analyze(
              ClassifierPcmMessage(
                sessionId: sessionId,
                sampleRate: chunk.sampleRate.hz,
                timestampMicros: chunk.timestamp.inMicroseconds,
                // Apple platforms are little-endian, like the transport.
                samples: samples.buffer.asUint8List(
                  samples.offsetInBytes,
                  samples.lengthInBytes,
                ),
              ),
            )
            .catchError(fail),
      );
    }

    // Listen before starting, so that no event of the session is missed.
    events = _events.listen((message) {
      if (done || message.sessionId != sessionId) return;
      final errorCode = message.errorCode;
      if (errorCode != null) {
        fail(
          CaptureException(
            CaptureErrorCode.values.asNameMap()[errorCode] ??
                CaptureErrorCode.unknown,
            message.errorMessage,
          ),
          null,
        );
        return;
      }
      final timestamp = Duration(microseconds: message.timestampMicros);
      for (final classification in message.classifications) {
        final detection = const SoundVocabulary().detection(
          backend: ClassifierBackend.apple,
          rawLabel: classification.identifier,
          confidence: classification.confidence,
          timestamp: timestamp,
        );
        if (detection != null) controller.addSync(detection);
      }
    }, onError: fail);

    started = _hostApi
        .startSession(
          ClassifierSessionMessage(
            sessionId: sessionId,
            minConfidence: config.minConfidence,
          ),
        )
        .then(
          (_) {
            if (done) return true;
            // Send PCM only once the host knows the session.
            chunks = pcm.listen(
              onChunk,
              onError: end,
              onDone: () => end(null, null),
            );
            if (controller.isPaused) chunks!.pause();
            return true;
          },
          onError: (Object error, StackTrace stackTrace) {
            fail(error, stackTrace);
            return false;
          },
        );

    controller
      ..onPause = () {
        chunks?.pause();
      }
      ..onResume = () {
        chunks?.resume();
      }
      ..onCancel = stop;
  });
}

CaptureException _toCaptureException(Object error) {
  if (error is CaptureException) return error;
  if (error is PlatformException) {
    final code = CaptureErrorCode.values.asNameMap()[error.code];
    return CaptureException(code ?? CaptureErrorCode.unknown, error.message);
  }
  return CaptureException(CaptureErrorCode.unknown, '$error');
}
