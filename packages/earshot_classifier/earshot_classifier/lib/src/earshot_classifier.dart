import 'package:earshot_classifier/src/classifier_options.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// {@template earshot_classifier}
/// Recognizes sounds from the device microphone, on-device.
///
/// Audio never leaves the device. earshot is informational and is not a
/// certified detector.
/// {@endtemplate}
class EarshotClassifier {
  /// {@macro earshot_classifier}
  const new({this.options = const ClassifierOptions()});

  /// How sounds are recognized.
  final ClassifierOptions options;

  /// Starts classifying and returns the sounds it recognizes.
  ///
  /// Each call to `listen()` on the returned stream starts its own session,
  /// and cancelling the subscription stops it. The stream never throws
  /// synchronously: failures are delivered as stream errors.
  ///
  /// Not implemented in 0.0.1: the stream errors with an
  /// [UnimplementedError].
  Stream<SoundDetection> detections() =>
      EarshotClassifierPlatform.instance.detections();
}
