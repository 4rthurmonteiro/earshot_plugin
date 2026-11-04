import 'package:earshot_capture_platform_interface/src/capture_config.dart';
import 'package:earshot_capture_platform_interface/src/capture_exception.dart';
import 'package:earshot_capture_platform_interface/src/capture_multiplexer.dart';
import 'package:earshot_capture_platform_interface/src/capture_state.dart';
import 'package:earshot_capture_platform_interface/src/microphone_permission_status.dart';
import 'package:earshot_capture_platform_interface/src/not_implemented.dart';
import 'package:earshot_capture_platform_interface/src/pcm_chunk.dart';
import 'package:earshot_capture_platform_interface/src/unsupported_earshot_capture.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// {@template earshot_capture_platform}
/// The interface that implementations of `earshot_capture` must extend.
///
/// Implementations must `extend` this class rather than `implement` it, so
/// that new methods added here are not breaking. Every method has a default
/// that completes with an [UnimplementedError].
/// {@endtemplate}
abstract class EarshotCapturePlatform extends PlatformInterface {
  /// {@macro earshot_capture_platform}
  new() : super(token: _token);

  static final Object _token = Object();

  static EarshotCapturePlatform _instance = UnsupportedEarshotCapture();

  /// The instance used by `earshot_capture`.
  ///
  /// Defaults to [UnsupportedEarshotCapture] on platforms without an
  /// endorsed implementation.
  static EarshotCapturePlatform get instance => _instance;

  /// Sets the instance used by `earshot_capture`.
  ///
  /// Platform implementations call this from their `registerWith()`.
  static set instance(EarshotCapturePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Reads the microphone permission status without prompting the user.
  Future<MicrophonePermissionStatus> microphonePermissionStatus() =>
      Future.error(UnimplementedError(kCaptureNotImplementedMessage));

  /// Asks the user for microphone access if they have not answered yet, and
  /// returns the resulting status.
  Future<MicrophonePermissionStatus> requestMicrophonePermission() =>
      Future.error(UnimplementedError(kCaptureNotImplementedMessage));

  /// Starts capture with [config] and returns the PCM it produces.
  ///
  /// Each `listen()` gets its own subscription, and cancelling the last one
  /// stops the native capture. Failures are delivered as [CaptureException]
  /// stream errors, never thrown synchronously. Implementations can use
  /// [CaptureMultiplexer] to share one native session.
  Stream<PcmChunk> pcm(CaptureConfig config) =>
      Stream.error(UnimplementedError(kCaptureNotImplementedMessage));

  /// The state changes of the capture session. Emits the current state first.
  Stream<CaptureState> stateChanges() =>
      Stream.error(UnimplementedError(kCaptureNotImplementedMessage));
}
