import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';

/// {@template earshot_capture}
/// Streams PCM audio from the device microphone.
///
/// Audio never leaves the device and is never written to disk.
/// {@endtemplate}
class EarshotCapture {
  /// {@macro earshot_capture}
  const new();

  /// Starts capture with [config] and returns the float32 mono PCM it
  /// produces.
  ///
  /// Each call to `listen()` on the returned stream gets its own
  /// subscription. Subscriptions share one microphone session, which stops
  /// when the last one is cancelled. Concurrent subscriptions must use the
  /// same [CaptureConfig.sampleRate]; otherwise the later one fails with
  /// [CaptureErrorCode.sampleRateConflict].
  ///
  /// The microphone is opened without voice processing (iOS `.measurement`
  /// mode, Android `UNPROCESSED` when the device supports it). When the
  /// system interrupts capture, for example during a phone call, chunks stop
  /// and [stateChanges] reports [CaptureState.interrupted]; capture resumes
  /// on its own afterwards.
  ///
  /// The stream never throws synchronously: failures are delivered as
  /// [CaptureException] stream errors, after which the stream closes. Ask for
  /// the permission with `MicrophonePermission.request()` first, or the
  /// stream fails with [CaptureErrorCode.permissionDenied].
  Stream<PcmChunk> pcm({CaptureConfig config = const CaptureConfig()}) =>
      EarshotCapturePlatform.instance.pcm(config);

  /// The state changes of the capture session, such as interruptions.
  ///
  /// Emits the current state first. Listening does not start capture.
  Stream<CaptureState> stateChanges() =>
      EarshotCapturePlatform.instance.stateChanges();
}
