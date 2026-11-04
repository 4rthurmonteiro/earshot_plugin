import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture_android/earshot_capture_android.dart';
import 'package:earshot_capture_android/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotCaptureHostApi extends Mock implements EarshotCaptureHostApi;

PcmChunkMessage _chunk(List<double> samples, int micros) => PcmChunkMessage(
  samples: Float32List.fromList(samples).buffer.asUint8List(),
  timestampMicros: micros,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(CaptureConfigMessage(sampleRateHz: 0)));

  group(EarshotCaptureAndroid, () {
    late EarshotCaptureHostApi hostApi;
    late StreamController<PcmChunkMessage> chunks;
    late StreamController<CaptureStateEventMessage> states;
    late EarshotCaptureAndroid platform;
    late EarshotCapturePlatform initialInstance;

    setUpAll(() => initialInstance = EarshotCapturePlatform.instance);
    tearDown(() => EarshotCapturePlatform.instance = initialInstance);

    setUp(() {
      hostApi = _MockEarshotCaptureHostApi();
      chunks = StreamController.broadcast();
      states = StreamController.broadcast();
      when(() => hostApi.startCapture(any())).thenAnswer((_) async {});
      when(hostApi.stopCapture).thenAnswer((_) async {});
      platform = EarshotCaptureAndroid(
        hostApi: hostApi,
        pcmChunkMessages: chunks.stream,
        captureStateMessages: states.stream,
      );
    });

    test('registerWith sets the platform instance', () {
      EarshotCaptureAndroid.registerWith();
      expect(EarshotCapturePlatform.instance, isA<EarshotCaptureAndroid>());
    });

    const mapping = {
      PermissionStatusMessage.granted: MicrophonePermissionStatus.granted,
      PermissionStatusMessage.denied: MicrophonePermissionStatus.denied,
      PermissionStatusMessage.undetermined:
          MicrophonePermissionStatus.undetermined,
      PermissionStatusMessage.restricted: MicrophonePermissionStatus.restricted,
    };

    group('microphonePermissionStatus', () {
      for (final MapEntry(key: message, value: status) in mapping.entries) {
        test('maps ${message.name} to ${status.name}', () async {
          when(hostApi.microphonePermissionStatus)
              .thenAnswer((_) async => message);

          await expectLater(
            platform.microphonePermissionStatus(),
            completion(status),
          );
          verify(hostApi.microphonePermissionStatus).called(1);
        });
      }

      test('forwards host errors', () {
        final error = PlatformException(code: 'channel-error');
        when(hostApi.microphonePermissionStatus).thenThrow(error);

        expect(platform.microphonePermissionStatus(), throwsA(same(error)));
      });
    });

    group('requestMicrophonePermission', () {
      for (final MapEntry(key: message, value: status) in mapping.entries) {
        test('maps ${message.name} to ${status.name}', () async {
          when(hostApi.requestMicrophonePermission)
              .thenAnswer((_) async => message);

          await expectLater(
            platform.requestMicrophonePermission(),
            completion(status),
          );
          verify(hostApi.requestMicrophonePermission).called(1);
        });
      }

      test('forwards host errors', () {
        final error = PlatformException(code: 'noActivity');
        when(hostApi.requestMicrophonePermission).thenThrow(error);

        expect(platform.requestMicrophonePermission(), throwsA(same(error)));
      });
    });

    group('pcm', () {
      test('starts the host at the requested rate and decodes PCM', () async {
        final received = <PcmChunk>[];
        final subscription = platform
            .pcm(const CaptureConfig(sampleRate: SampleRate.hz44100))
            .listen(received.add);
        await pumpEventQueue();

        final config =
            verify(() => hostApi.startCapture(captureAny())).captured.single
                as CaptureConfigMessage;
        expect(config.sampleRateHz, 44100);

        chunks
          ..add(_chunk([0.5, -0.25], 2000))
          ..add(_chunk([1], 102000));
        await pumpEventQueue();

        expect(received, [
          PcmChunk(
            samples: Float32List.fromList([0.5, -0.25]),
            sampleRate: SampleRate.hz44100,
            timestamp: Duration.zero,
          ),
          PcmChunk(
            samples: Float32List.fromList([1]),
            sampleRate: SampleRate.hz44100,
            timestamp: const Duration(milliseconds: 100),
          ),
        ]);

        await subscription.cancel();
        verify(hostApi.stopCapture).called(1);
      });

      final startErrors = <Object, CaptureException>{
        PlatformException(code: 'permissionDenied', message: 'no'):
            const CaptureException(CaptureErrorCode.permissionDenied, 'no'),
        PlatformException(code: 'audioUnavailable'): const CaptureException(
          CaptureErrorCode.audioUnavailable,
        ),
        PlatformException(code: 'somethingElse', message: 'x'):
            const CaptureException(CaptureErrorCode.unknown, 'x'),
        StateError('boom'): const CaptureException(
          CaptureErrorCode.unknown,
          'Bad state: boom',
        ),
      };

      for (final MapEntry(key: error, value: expected) in startErrors.entries) {
        test('maps start error $error', () async {
          when(() => hostApi.startCapture(any())).thenThrow(error);

          await expectLater(
            platform.pcm(const CaptureConfig()),
            emitsInOrder([emitsError(expected), emitsDone]),
          );
        });
      }

      test('maps native stream errors', () async {
        final stream = platform.pcm(const CaptureConfig());
        final expectation = expectLater(
          stream,
          emitsInOrder([
            emitsError(
              const CaptureException(
                CaptureErrorCode.audioUnavailable,
                'record died',
              ),
            ),
            emitsDone,
          ]),
        );
        await pumpEventQueue();

        chunks.addError(
          PlatformException(code: 'audioUnavailable', message: 'record died'),
        );
        await expectation;
      });

      test('passes capture exceptions through', () async {
        const error = CaptureException(CaptureErrorCode.unknown);
        final stream = platform.pcm(const CaptureConfig());
        final expectation = expectLater(
          stream,
          emitsInOrder([emitsError(error), emitsDone]),
        );
        await pumpEventQueue();

        chunks.addError(error);
        await expectation;
      });
    });

    test('stateChanges maps the host states', () async {
      final received = <CaptureState>[];
      final listener = platform.stateChanges().listen(received.add);
      final subscription = platform.pcm(const CaptureConfig()).listen((_) {});
      await pumpEventQueue();

      for (final state in CaptureStateMessage.values.reversed) {
        states.add(CaptureStateEventMessage(state: state));
      }
      await pumpEventQueue();
      await subscription.cancel();
      await pumpEventQueue();

      expect(received, [
        CaptureState.idle,
        CaptureState.capturing,
        CaptureState.interrupted,
        CaptureState.capturing,
        CaptureState.idle,
      ]);
      await listener.cancel();
    });
  });
}
