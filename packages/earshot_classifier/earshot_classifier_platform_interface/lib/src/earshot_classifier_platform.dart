import 'package:earshot_classifier_platform_interface/src/classifier_backend.dart';
import 'package:earshot_classifier_platform_interface/src/classifier_config.dart';
import 'package:earshot_classifier_platform_interface/src/not_implemented.dart';
import 'package:earshot_classifier_platform_interface/src/sound_detection.dart';
import 'package:earshot_classifier_platform_interface/src/unsupported_earshot_classifier.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/sound_vocabulary.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// {@template earshot_classifier_platform}
/// The interface that implementations of `earshot_classifier` must extend.
///
/// An implementation is a backend that runs its own microphone session, such
/// as Apple SoundAnalysis on iOS and macOS. `earshot_classifier` uses
/// [instance] for [ClassifierBackend.apple], and for [ClassifierBackend.auto]
/// on iOS and macOS when [isAvailable] completes with `true`. It runs
/// [ClassifierBackend.yamnet] itself, in Dart.
///
/// Implementations must `extend` this class rather than `implement` it, so
/// that new methods added here are not breaking. Every method has a default
/// that completes with an [UnimplementedError].
/// {@endtemplate}
abstract class EarshotClassifierPlatform extends PlatformInterface {
  /// {@macro earshot_classifier_platform}
  new() : super(token: _token);

  static final Object _token = Object();

  static EarshotClassifierPlatform _instance = UnsupportedEarshotClassifier();

  /// The instance used by `earshot_classifier`.
  ///
  /// Defaults to [UnsupportedEarshotClassifier] on platforms without an
  /// endorsed implementation.
  static EarshotClassifierPlatform get instance => _instance;

  /// Sets the instance used by `earshot_classifier`.
  ///
  /// Platform implementations call this from their `registerWith()`.
  static set instance(EarshotClassifierPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Whether this backend can run on this device, for example because the
  /// OS is recent enough.
  ///
  /// Must never prompt the user, including for the microphone permission.
  /// `earshot_classifier` falls back to [ClassifierBackend.yamnet] for
  /// [ClassifierBackend.auto] when this completes with `false` or with an
  /// error.
  Future<bool> isAvailable() =>
      Future.error(UnimplementedError(kClassifierNotImplementedMessage));

  /// Opens this backend's own microphone session, classifies it, and returns
  /// what it recognizes.
  ///
  /// The contract for implementations:
  ///
  /// - Each `listen()` starts its own session, and cancelling the
  ///   subscription stops it and releases the microphone.
  /// - Never throw synchronously: deliver failures, such as a denied
  ///   microphone permission, as stream errors.
  /// - Report every label scored at or above [ClassifierConfig.minConfidence]
  ///   in each analysis window, built with [SoundVocabulary.detection] so
  ///   that the sound, group and backend are filled in. Detections of the
  ///   same window share a `timestamp`, relative to the start of the session.
  /// - Do not smooth: `earshot_classifier` applies `Smoothing` on top, the
  ///   same way for every backend.
  Stream<SoundDetection> detections(ClassifierConfig config) =>
      Stream.error(UnimplementedError(kClassifierNotImplementedMessage));
}
