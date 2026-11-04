import 'package:earshot_classifier_platform_interface/src/not_implemented.dart';
import 'package:earshot_classifier_platform_interface/src/sound_detection.dart';
import 'package:earshot_classifier_platform_interface/src/unsupported_earshot_classifier.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// {@template earshot_classifier_platform}
/// The interface that implementations of `earshot_classifier` must extend.
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

  /// Starts classifying the microphone and returns what it recognizes.
  ///
  /// Classification stops when the subscription is cancelled.
  Stream<SoundDetection> detections() =>
      Stream.error(UnimplementedError(kClassifierNotImplementedMessage));
}
