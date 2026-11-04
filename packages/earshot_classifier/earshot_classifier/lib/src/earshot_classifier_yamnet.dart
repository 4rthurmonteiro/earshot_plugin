import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// {@template earshot_classifier_yamnet}
/// The [ClassifierBackend.yamnet] implementation of
/// [EarshotClassifierPlatform], written in Dart.
///
/// Registered on Android through `dartPluginClass`. Internal to
/// `earshot_classifier` and not exported.
///
/// Not implemented in 0.0.1: every method completes with an
/// [UnimplementedError].
/// {@endtemplate}
class EarshotClassifierYamnet extends EarshotClassifierPlatform {
  /// {@macro earshot_classifier_yamnet}
  new();

  /// Registers this class as the [EarshotClassifierPlatform.instance].
  static void registerWith() {
    EarshotClassifierPlatform.instance = EarshotClassifierYamnet();
  }
}
