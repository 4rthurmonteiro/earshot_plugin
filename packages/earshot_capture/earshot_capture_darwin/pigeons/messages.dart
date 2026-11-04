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

/// The state of the native capture session.
enum CaptureStateMessage { idle, capturing, interrupted }

/// The configuration the host opens the microphone with.
class CaptureConfigMessage {
  new({required this.sampleRateHz});

  /// The rate PCM is delivered at, in hertz: 16000, 44100 or 48000.
  int sampleRateHz;
}

/// A chunk of float32 mono PCM produced by the host.
class PcmChunkMessage {
  new({required this.samples, required this.timestampMicros});

  /// The mono float32 samples, little-endian, nominally in the range -1 to 1.
  Uint8List samples;

  /// The time of the first sample since capture started, in microseconds.
  int timestampMicros;
}

/// A capture state change produced by the host.
class CaptureStateEventMessage {
  new({required this.state});

  /// The new state.
  CaptureStateMessage state;
}

/// The calls Dart makes to the iOS and macOS host.
@HostApi()
abstract class EarshotCaptureHostApi {
  /// Reads the microphone permission status without prompting the user.
  PermissionStatusMessage microphonePermissionStatus();

  /// Asks the user for microphone access if needed and returns the result.
  @async
  PermissionStatusMessage requestMicrophonePermission();

  /// Opens the microphone with [config]. Chunks arrive on `pcmChunks`.
  void startCapture(CaptureConfigMessage config);

  /// Closes the microphone. Does nothing if capture is not running.
  void stopCapture();
}

/// The streams the iOS and macOS host sends to Dart.
@EventChannelApi()
abstract class EarshotCaptureEventApi {
  /// The PCM of the running capture session.
  PcmChunkMessage pcmChunks();

  /// The state changes of the capture session.
  CaptureStateEventMessage captureStates();
}
