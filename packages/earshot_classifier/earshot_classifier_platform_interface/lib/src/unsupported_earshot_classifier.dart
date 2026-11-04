import 'package:earshot_classifier_platform_interface/src/earshot_classifier_platform.dart';

/// {@template unsupported_earshot_classifier}
/// The default [EarshotClassifierPlatform] on platforms without an endorsed
/// implementation, such as web, Linux and Windows.
///
/// Every method completes with an [UnimplementedError].
/// {@endtemplate}
class UnsupportedEarshotClassifier extends EarshotClassifierPlatform {
  /// {@macro unsupported_earshot_classifier}
  new();
}
