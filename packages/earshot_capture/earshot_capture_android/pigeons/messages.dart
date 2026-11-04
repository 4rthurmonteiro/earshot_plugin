import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'earshot_capture_android',
    kotlinOut: 'android/src/main/kotlin/dev/earshot/capture/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'dev.earshot.capture'),
  ),
)
/// The microphone permission status, as reported by the host.
enum PermissionStatusMessage { granted, denied, undetermined, restricted }

/// The calls Dart makes to the Android host.
@HostApi()
abstract class EarshotCaptureHostApi {
  /// Reads the microphone permission status without prompting the user.
  PermissionStatusMessage microphonePermissionStatus();
}
