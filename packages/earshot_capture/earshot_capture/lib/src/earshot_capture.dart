import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';

/// {@template earshot_capture}
/// Streams PCM audio from the device microphone.
///
/// Audio never leaves the device and is never written to disk.
/// {@endtemplate}
class EarshotCapture {
  /// {@macro earshot_capture}
  const new();

  /// Starts capture with [config] and returns the PCM it produces.
  ///
  /// Each call to `listen()` on the returned stream starts its own capture
  /// session, and cancelling the subscription stops it. The stream never
  /// throws synchronously: failures are delivered as stream errors.
  ///
  /// Not implemented in 0.0.1: the stream errors with an
  /// [UnimplementedError].
  Stream<PcmChunk> pcm({CaptureConfig config = const CaptureConfig()}) =>
      EarshotCapturePlatform.instance.pcm(config);

  /// The state changes of the capture session, such as interruptions.
  ///
  /// Not implemented in 0.0.1: the stream errors with an
  /// [UnimplementedError].
  Stream<CaptureState> stateChanges() =>
      EarshotCapturePlatform.instance.stateChanges();
}
