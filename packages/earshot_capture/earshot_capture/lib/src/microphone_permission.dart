import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';

/// {@template microphone_permission}
/// Reads and requests the microphone permission.
///
/// Apps must declare the microphone usage themselves:
/// `NSMicrophoneUsageDescription` in the iOS and macOS `Info.plist`, plus the
/// `com.apple.security.device.audio-input` entitlement on macOS.
/// {@endtemplate}
class MicrophonePermission {
  /// {@macro microphone_permission}
  const new();

  /// Reads the microphone permission status. Never prompts the user.
  ///
  /// On Android this returns [MicrophonePermissionStatus.granted] or
  /// [MicrophonePermissionStatus.denied] only.
  Future<MicrophonePermissionStatus> status() =>
      EarshotCapturePlatform.instance.microphonePermissionStatus();

  /// Asks the user for microphone access if they have not answered yet, and
  /// returns the resulting status.
  ///
  /// Not implemented in 0.0.1: completes with an [UnimplementedError].
  Future<MicrophonePermissionStatus> request() =>
      EarshotCapturePlatform.instance.requestMicrophonePermission();
}
