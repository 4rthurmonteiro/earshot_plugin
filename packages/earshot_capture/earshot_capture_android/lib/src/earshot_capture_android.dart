import 'package:earshot_capture_android/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// {@template earshot_capture_android}
/// The Android implementation of [EarshotCapturePlatform].
/// {@endtemplate}
class EarshotCaptureAndroid extends EarshotCapturePlatform {
  /// {@macro earshot_capture_android}
  new({@visibleForTesting EarshotCaptureHostApi? hostApi})
    : _hostApi = hostApi ?? EarshotCaptureHostApi();

  final EarshotCaptureHostApi _hostApi;

  /// Registers this class as the [EarshotCapturePlatform.instance].
  static void registerWith() {
    EarshotCapturePlatform.instance = EarshotCaptureAndroid();
  }

  /// Reads the `RECORD_AUDIO` permission without prompting the user.
  ///
  /// Android cannot tell "never asked" apart from "denied" without an
  /// `Activity`, so this returns [MicrophonePermissionStatus.granted] or
  /// [MicrophonePermissionStatus.denied] only.
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
