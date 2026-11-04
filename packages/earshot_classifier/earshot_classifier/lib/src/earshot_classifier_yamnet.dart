import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// {@template earshot_classifier_yamnet}
/// The [ClassifierBackend.yamnet] implementation of
/// [EarshotClassifierPlatform], written in Dart.
///
/// It captures 16 kHz PCM with `earshot_capture` and classifies it with the
/// bundled YAMNet model through LiteRT, in a background isolate. It runs on
/// every platform: `EarshotClassifier` uses it directly for
/// [ClassifierBackend.yamnet], and it is registered as the
/// [EarshotClassifierPlatform.instance] on Android through
/// `dartPluginClass`.
///
/// Internal to `earshot_classifier` and not exported.
/// {@endtemplate}
class EarshotClassifierYamnet extends EarshotClassifierPlatform {
  /// {@macro earshot_classifier_yamnet}
  new();

  /// Registers this class as the [EarshotClassifierPlatform.instance].
  static void registerWith() {
    EarshotClassifierPlatform.instance = EarshotClassifierYamnet();
  }

  /// YAMNet runs on every platform, so this always completes with `true`.
  @override
  Future<bool> isAvailable() => Future.value(true);

  @override
  Stream<SoundDetection> detections(ClassifierConfig config) =>
      classifyWithYamnet(const EarshotCapture().pcm, config);
}
