import 'dart:async';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/src/classifier_options.dart';
import 'package:earshot_classifier/src/detection_smoother.dart';
import 'package:earshot_classifier/src/earshot_classifier_yamnet.dart';
import 'package:earshot_classifier/src/smoothing.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// {@template earshot_classifier}
/// Recognizes sounds on-device.
///
/// [options] pick the backend, the confidence threshold and the smoothing.
/// Audio never leaves the device. earshot is informational and is not a
/// certified detector: never rely on it for safety, including smoke and
/// carbon monoxide alarms.
/// {@endtemplate}
class EarshotClassifier {
  /// {@macro earshot_classifier}
  const new({this.options = const ClassifierOptions()});

  /// How sounds are recognized.
  final ClassifierOptions options;

  /// Starts classifying the microphone and returns the sounds it confirms.
  ///
  /// The backend comes from [ClassifierOptions.backend]:
  ///
  /// - [ClassifierBackend.yamnet] captures 16 kHz PCM with `earshot_capture`
  ///   and runs YAMNet in Dart, on every platform.
  /// - [ClassifierBackend.apple] captures 16 kHz PCM with `earshot_capture`
  ///   and runs Apple SoundAnalysis on it, on iOS and macOS. On other
  ///   platforms the stream errors with an [UnsupportedError].
  /// - With no backend set, [ClassifierBackend.apple] is used on iOS and
  ///   macOS when it is available, and [ClassifierBackend.yamnet] otherwise.
  ///
  /// Detections below [ClassifierOptions.minConfidence] are dropped, and the
  /// rest are confirmed with [ClassifierOptions.smoothing] before they are
  /// reported.
  ///
  /// Each call to `listen()` on the returned stream starts its own session,
  /// and cancelling the subscription stops it. The stream never throws
  /// synchronously: failures, such as a denied microphone permission, are
  /// delivered as stream errors.
  Stream<SoundDetection> detections() => _confirmed(_openBackend);

  /// Classifies [pcm] and returns the sounds it confirms.
  ///
  /// Use this to share one capture stream with other consumers, such as a
  /// level meter. The backend is picked as in [detections]:
  ///
  /// - [ClassifierBackend.yamnet] resamples PCM at 44.1 or 48 kHz to 16 kHz
  ///   and runs YAMNet in Dart.
  /// - [ClassifierBackend.apple] runs Apple SoundAnalysis on [pcm], at any
  ///   rate, on iOS and macOS. On other platforms the stream errors with an
  ///   [UnsupportedError].
  /// - With no backend set, [ClassifierBackend.apple] is used on iOS and
  ///   macOS when it is available, and [ClassifierBackend.yamnet] otherwise.
  ///
  /// Detections are filtered and smoothed as in [detections].
  ///
  /// Each call to `listen()` on the returned stream listens to [pcm], so
  /// [pcm] must be a broadcast stream to be listened to more than once.
  /// Cancelling the subscription cancels the subscription to [pcm].
  Stream<SoundDetection> classify(Stream<PcmChunk> pcm) => _confirmed(() async {
    final platform = await _nativeBackend();
    if (platform != null) return platform.classify(pcm, _config);
    return classifyWithYamnet(() => pcm, _config);
  });

  ClassifierConfig get _config =>
      ClassifierConfig(minConfidence: options.minConfidence);

  Future<Stream<SoundDetection>> _openBackend() async {
    final platform = await _nativeBackend();
    if (platform != null) return platform.detections(_config);
    return EarshotClassifierYamnet().detections(_config);
  }

  /// The native backend that [options] select on this platform, or `null`
  /// for [ClassifierBackend.yamnet].
  ///
  /// Throws an [UnsupportedError] for [ClassifierBackend.apple] off iOS and
  /// macOS.
  Future<EarshotClassifierPlatform?> _nativeBackend() async {
    final platform = EarshotClassifierPlatform.instance;
    switch (options.backend) {
      case ClassifierBackend.yamnet:
        return null;
      case ClassifierBackend.apple:
        if (!_isApplePlatform) {
          throw UnsupportedError(
            'The apple backend is only available on iOS and macOS.',
          );
        }
        return platform;
      case null:
        if (_isApplePlatform && await _isAvailable(platform)) return platform;
        return null;
    }
  }

  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<bool> _isAvailable(EarshotClassifierPlatform platform) async {
    try {
      return await platform.isAvailable();
    } on Object {
      // A platform that cannot tell, such as a stub, is unavailable.
      return false;
    }
  }

  /// Opens a raw detection stream on each `listen()`, then drops detections
  /// below the threshold and confirms the rest with [Smoothing].
  Stream<SoundDetection> _confirmed(
    Future<Stream<SoundDetection>> Function() open,
  ) => Stream.multi((controller) {
    final smoother = DetectionSmoother(options.smoothing);
    StreamSubscription<SoundDetection>? subscription;
    var cancelled = false;
    controller.onCancel = () {
      cancelled = true;
      return subscription?.cancel();
    };
    unawaited(
      open().then(
        (raw) {
          if (cancelled) return;
          subscription = raw.listen(
            (detection) {
              if (detection.confidence < options.minConfidence) return;
              final confirmed = smoother.add(detection);
              if (confirmed != null) controller.addSync(confirmed);
            },
            onError: controller.addErrorSync,
            onDone: controller.closeSync,
          );
          controller
            ..onPause = subscription!.pause
            ..onResume = subscription!.resume;
        },
        onError: (Object error, StackTrace stackTrace) {
          if (cancelled) return;
          controller
            ..addErrorSync(error, stackTrace)
            ..closeSync();
        },
      ),
    );
  });
}
