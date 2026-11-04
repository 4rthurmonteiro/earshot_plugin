import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'earshot_capture_darwin',
    swiftOut: 'darwin/earshot_capture_darwin/Sources/earshot_capture_darwin/Messages.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
/// The microphone permission status, as reported by the host.
enum PermissionStatusMessage { granted, denied, undetermined, restricted }

/// The calls Dart makes to the iOS and macOS host.
@HostApi()
abstract class EarshotCaptureHostApi {
  /// Reads the microphone permission status without prompting the user.
  PermissionStatusMessage microphonePermissionStatus();
}
