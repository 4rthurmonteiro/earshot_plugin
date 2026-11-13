import 'dart:async';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/src/classifier_options.dart';
import 'package:earshot_classifier/src/detection_smoother.dart';
import 'package:earshot_classifier/src/earshot_classifier_yamnet.dart';
import 'package:earshot_classifier/src/smoothing.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  ///   platforms the stream errors with a [ClassifierException] with
  ///   [ClassifierErrorCode.unsupported].
  /// - With no backend set, [ClassifierBackend.apple] is used on iOS and
  ///   macOS when it is available, and [ClassifierBackend.yamnet] otherwise.
  ///
  /// Detections below [ClassifierOptions.minConfidence] are dropped, and the
  /// rest are confirmed with [ClassifierOptions.smoothing] before they are
  /// reported.
  ///
  /// Each call to `listen()` on the returned stream starts its own session,
  /// and cancelling the subscription stops it. The stream never throws
  /// synchronously. Failures are delivered as stream errors: a
  /// [CaptureException] when the microphone fails, for example because the
  /// permission is denied, a [ClassifierException] when the backend fails,
  /// and an [ArgumentError] when [options] are invalid, such as a
  /// [ClassifierOptions.minConfidence] outside 0 to 1.
  Stream<SoundDetection> detections() => _confirmed(_openBackend);

  /// Classifies [pcm] and returns the sounds it confirms.
  ///
  /// Use this to share one capture stream with other consumers, such as a
  /// level meter. The backend is picked as in [detections]:
  ///
  /// - [ClassifierBackend.yamnet] resamples PCM at 44.1 or 48 kHz to 16 kHz
  ///   and runs YAMNet in Dart.
  /// - [ClassifierBackend.apple] runs Apple SoundAnalysis on [pcm], at any
  ///   rate, on iOS and macOS. On other platforms the stream errors with a
  ///   [ClassifierException] with [ClassifierErrorCode.unsupported].
  /// - With no backend set, [ClassifierBackend.apple] is used on iOS and
  ///   macOS when it is available, and [ClassifierBackend.yamnet] otherwise.
  ///
  /// Detections are filtered and smoothed as in [detections]. Errors from
  /// [pcm], such as a [CaptureException], are forwarded unchanged, and
  /// backend failures are delivered as a [ClassifierException]. Invalid
  /// [options] fail the stream with an [ArgumentError] without listening to
  /// [pcm].
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
  /// Throws a [ClassifierException] for [ClassifierBackend.apple] off iOS
  /// and macOS.
  Future<EarshotClassifierPlatform?> _nativeBackend() async {
    final platform = EarshotClassifierPlatform.instance;
    // Comparisons rather than a switch: a switch over ClassifierBackend is
    // not exhaustive against the 0.2.0 platform interface, which still has
    // `auto`, and pana's downgrade check resolves that version.
    final backend = options.backend;
    if (backend == ClassifierBackend.yamnet) return null;
    if (backend == ClassifierBackend.apple) {
      if (!_isApplePlatform) {
        throw const ClassifierException(
          ClassifierErrorCode.unsupported,
          'The apple backend is only available on iOS and macOS.',
        );
      }
      return platform;
    }
    if (_isApplePlatform && await _isAvailable(platform)) return platform;
    return null;
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
  /// below the threshold and confirms the rest with [Smoothing]. Errors go
  /// through [toClassifierError].
  ///
  /// Invalid [options] fail the stream with an [ArgumentError] before
  /// anything is opened, because release builds skip the constructor
  /// asserts.
  Stream<SoundDetection> _confirmed(
    Future<Stream<SoundDetection>> Function() open,
  ) => Stream.multi((controller) {
    final invalid = _validate(options);
    if (invalid != null) {
      controller
        ..addErrorSync(invalid)
        ..closeSync();
      return;
    }
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
            onError: (Object error, StackTrace stackTrace) =>
                controller.addErrorSync(toClassifierError(error), stackTrace),
            onDone: controller.closeSync,
          );
          controller
            ..onPause = subscription!.pause
            ..onResume = subscription!.resume;
        },
        onError: (Object error, StackTrace stackTrace) {
          if (cancelled) return;
          controller
            ..addErrorSync(toClassifierError(error), stackTrace)
            ..closeSync();
        },
      ),
    );
  });
}

/// The [ArgumentError] for the first invalid value in [options], or `null`
/// if they are valid.
ArgumentError? _validate(ClassifierOptions options) {
  final minConfidence = options.minConfidence;
  if (!(minConfidence >= 0 && minConfidence <= 1)) {
    return ArgumentError.value(
      minConfidence,
      'minConfidence',
      'must be between 0 and 1',
    );
  }
  final hits = options.smoothing.hits;
  if (hits < 1) {
    return ArgumentError.value(hits, 'smoothing.hits', 'must be at least 1');
  }
  return null;
}

/// Keeps a [CaptureException] or a [ClassifierException] as it is, and turns
/// any other [error] from a backend into a [ClassifierException]:
///
/// - An [UnsupportedError], including an [UnimplementedError], is
///   [ClassifierErrorCode.unsupported].
/// - A [PlatformException] whose code is the name of a [ClassifierErrorCode]
///   gets that code.
/// - Anything else is [ClassifierErrorCode.unknown].
@internal
Object toClassifierError(Object error) => switch (error) {
  CaptureException() || ClassifierException() => error,
  UnsupportedError(:final message) => ClassifierException(
    ClassifierErrorCode.unsupported,
    message,
  ),
  PlatformException(:final code, :final message) => ClassifierException(
    ClassifierErrorCode.values.asNameMap()[code] ?? ClassifierErrorCode.unknown,
    message,
  ),
  _ => ClassifierException(ClassifierErrorCode.unknown, '$error'),
};
