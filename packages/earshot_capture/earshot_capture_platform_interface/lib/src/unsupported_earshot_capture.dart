import 'package:earshot_capture_platform_interface/src/earshot_capture_platform.dart';

/// {@template unsupported_earshot_capture}
/// The default [EarshotCapturePlatform] on platforms without an endorsed
/// implementation, such as web, Linux and Windows.
///
/// Every method completes with an [UnimplementedError].
/// {@endtemplate}
class UnsupportedEarshotCapture extends EarshotCapturePlatform {
  /// {@macro unsupported_earshot_capture}
  new();
}
