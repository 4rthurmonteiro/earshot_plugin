import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier_darwin/src/messages.g.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// {@template earshot_classifier_darwin}
/// The iOS and macOS implementation of [EarshotClassifierPlatform], backed by
/// the [ClassifierBackend.apple] backend: Apple's on-device SoundAnalysis
/// framework (`SNClassifySoundRequest`, classifier version 1).
///
/// Requires iOS 15 or macOS 12. Classification never prompts for the
/// microphone permission: request it first, for example with
/// `EarshotCapture.requestMicrophonePermission`.
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including smoke and carbon monoxide alarms.
/// {@endtemplate}
class EarshotClassifierDarwin extends EarshotClassifierPlatform {
  /// {@macro earshot_classifier_darwin}
  ///
  /// Tests can pass the Pigeon host API and the native event stream.
  new({
    @visibleForTesting EarshotClassifierHostApi? hostApi,
    @visibleForTesting this._eventMessages,
  }) : _hostApi = hostApi ?? EarshotClassifierHostApi();

  final EarshotClassifierHostApi _hostApi;
  final Stream<ClassifierEventMessage>? _eventMessages;

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

  /// Classifies the microphone with SoundAnalysis.
  ///
  /// Each `listen()` starts its own session with its own
  /// `SNAudioStreamAnalyzer`. Sessions that run at the same time share one
  /// `AVAudioEngine` input tap, and the microphone is released when the last
  /// one is cancelled. On iOS the audio session uses the `.record` category
  /// and the `.measurement` mode.
  ///
  /// SoundAnalysis analyzes windows of about one second that overlap by
  /// half. Every label of a window at or above
  /// [ClassifierConfig.minConfidence] is reported, with the start of the
  /// window as its timestamp.
  ///
  /// Failures are delivered as a [CaptureException], after which the stream
  /// closes: [CaptureErrorCode.permissionDenied] if microphone access has
  /// not been granted, [CaptureErrorCode.audioUnavailable] if the microphone
  /// cannot be opened or reopened after an interruption, and
  /// [CaptureErrorCode.unknown] otherwise. Interruptions, such as a phone
  /// call, pause the detections, which resume on their own afterwards.
  @override
  Stream<SoundDetection> detections(ClassifierConfig config) =>
      Stream.multi((controller) {
        final sessionId = _nextSessionId++;
        var done = false;
        StreamSubscription<ClassifierEventMessage>? events;

        void fail(Object error, StackTrace? stackTrace) {
          if (done) return;
          done = true;
          unawaited(events?.cancel());
          controller
            ..addErrorSync(_toCaptureException(error), stackTrace)
            ..closeSync();
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

        final started = _hostApi
            .startSession(
              ClassifierSessionMessage(
                sessionId: sessionId,
                minConfidence: config.minConfidence,
              ),
            )
            .then(
              (_) => true,
              onError: (Object error, StackTrace stackTrace) {
                fail(error, stackTrace);
                return false;
              },
            );

        controller.onCancel = () async {
          done = true;
          await events?.cancel();
          // Waiting for the start means a stop never overtakes it.
          if (!await started) return;
          try {
            await _hostApi.stopSession(sessionId);
          } on Object {
            // The session is gone either way; nothing is listening anymore.
          }
        };
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
