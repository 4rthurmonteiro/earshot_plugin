import 'package:earshot_capture_darwin/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// {@template earshot_capture_darwin}
/// The iOS and macOS implementation of [EarshotCapturePlatform].
/// {@endtemplate}
class EarshotCaptureDarwin extends EarshotCapturePlatform {
  /// {@macro earshot_capture_darwin}
  new({@visibleForTesting EarshotCaptureHostApi? hostApi})
    : _hostApi = hostApi ?? EarshotCaptureHostApi();

  final EarshotCaptureHostApi _hostApi;

  /// Registers this class as the [EarshotCapturePlatform.instance].
  static void registerWith() {
    EarshotCapturePlatform.instance = EarshotCaptureDarwin();
  }

  /// Reads the record permission without prompting the user.
  @override
  Future<MicrophonePermissionStatus> microphonePermissionStatus() async {
    final status = await _hostApi.microphonePermissionStatus();
    return switch (status) {
      PermissionStatusMessage.granted => MicrophonePermissionStatus.granted,
      PermissionStatusMessage.denied => MicrophonePermissionStatus.denied,
      PermissionStatusMessage.undetermined =>
        MicrophonePermissionStatus.undetermined,
      PermissionStatusMessage.restricted =>
        MicrophonePermissionStatus.restricted,
    };
  }
}
