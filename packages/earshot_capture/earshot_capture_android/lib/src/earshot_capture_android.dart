import 'dart:async';

import 'package:earshot_capture_android/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// {@template earshot_capture_android}
/// The Android implementation of [EarshotCapturePlatform].
/// {@endtemplate}
class EarshotCaptureAndroid extends EarshotCapturePlatform {
  /// {@macro earshot_capture_android}
  ///
  /// Tests can pass the Pigeon host API and the native event streams.
  new({
    @visibleForTesting EarshotCaptureHostApi? hostApi,
    @visibleForTesting this._pcmChunkMessages,
    @visibleForTesting this._captureStateMessages,
  }) : _hostApi = hostApi ?? EarshotCaptureHostApi();

  final EarshotCaptureHostApi _hostApi;
  final Stream<PcmChunkMessage>? _pcmChunkMessages;
  final Stream<CaptureStateEventMessage>? _captureStateMessages;

  // One Dart stream per event channel: a second `receiveBroadcastStream()`
  // on the same channel would steal the first one's messages.
  late final CaptureMultiplexer _multiplexer = CaptureMultiplexer(
    start: (config) async {
      try {
        await _hostApi.startCapture(
          CaptureConfigMessage(sampleRateHz: config.sampleRate.hz),
        );
      } on Object catch (error) {
        throw _toCaptureException(error);
      }
    },
    stop: _hostApi.stopCapture,
    nativePcm: (_pcmChunkMessages ?? pcmChunks())
        .map(_toNativePcm)
        .transform(_captureErrors()),
    nativeStates: (_captureStateMessages ?? captureStates()).map(
      (message) => switch (message.state) {
        CaptureStateMessage.idle => CaptureState.idle,
        CaptureStateMessage.capturing => CaptureState.capturing,
        CaptureStateMessage.interrupted => CaptureState.interrupted,
      },
    ),
  );

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
  Future<MicrophonePermissionStatus> microphonePermissionStatus() async =>
      _toStatus(await _hostApi.microphonePermissionStatus());

  /// Requests `RECORD_AUDIO` through the foreground `Activity`.
  ///
  /// Completes with a `PlatformException` when the plugin is not attached
  /// to an `Activity`.
  @override
  Future<MicrophonePermissionStatus> requestMicrophonePermission() async =>
      _toStatus(await _hostApi.requestMicrophonePermission());

  /// Captures with `AudioRecord` in `ENCODING_PCM_FLOAT`, from the
  /// `UNPROCESSED` source when the device supports it and from
  /// `VOICE_RECOGNITION` otherwise.
  @override
  Stream<PcmChunk> pcm(CaptureConfig config) => _multiplexer.pcm(config);

  @override
  Stream<CaptureState> stateChanges() => _multiplexer.stateChanges();
}

MicrophonePermissionStatus _toStatus(PermissionStatusMessage status) =>
    switch (status) {
      PermissionStatusMessage.granted => MicrophonePermissionStatus.granted,
      PermissionStatusMessage.denied => MicrophonePermissionStatus.denied,
      PermissionStatusMessage.undetermined =>
        MicrophonePermissionStatus.undetermined,
      PermissionStatusMessage.restricted =>
        MicrophonePermissionStatus.restricted,
    };

NativePcm _toNativePcm(PcmChunkMessage message) {
  // The bytes may not be 4-byte aligned in the message buffer, so copy them
  // into a fresh Float32List instead of viewing them in place.
  final samples = Float32List(message.samples.lengthInBytes ~/ 4);
  samples.buffer.asUint8List().setAll(0, message.samples);
  return (
    samples: samples,
    timestamp: Duration(microseconds: message.timestampMicros),
  );
}

StreamTransformer<NativePcm, NativePcm> _captureErrors() =>
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(_toCaptureException(error), stackTrace),
    );

CaptureException _toCaptureException(Object error) {
  if (error is CaptureException) return error;
  if (error is PlatformException) {
    final code = CaptureErrorCode.values.asNameMap()[error.code];
    return CaptureException(code ?? CaptureErrorCode.unknown, error.message);
  }
  return CaptureException(CaptureErrorCode.unknown, '$error');
}
