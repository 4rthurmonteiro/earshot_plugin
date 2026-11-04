import 'dart:typed_data';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockEarshotCapturePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotCapturePlatform;

void main() {
  late EarshotCapturePlatform platform;

  setUpAll(() => registerFallbackValue(const CaptureConfig()));

  setUp(() {
    platform = _MockEarshotCapturePlatform();
    EarshotCapturePlatform.instance = platform;
  });

  group(EarshotCapture, () {
    test('pcm delegates to the platform with the default config', () {
      final chunk = PcmChunk(
        samples: Float32List(2),
        sampleRate: SampleRate.hz16000,
        timestamp: Duration.zero,
      );
      when(() => platform.pcm(any())).thenAnswer((_) => Stream.value(chunk));

      expect(const EarshotCapture().pcm(), emits(chunk));
      verify(() => platform.pcm(const CaptureConfig())).called(1);
    });

    test('pcm passes the given config to the platform', () {
      const config = CaptureConfig(sampleRate: SampleRate.hz48000);
      when(() => platform.pcm(any())).thenAnswer((_) => const Stream.empty());

      const EarshotCapture().pcm(config: config);
      verify(() => platform.pcm(config)).called(1);
    });

    test('stateChanges delegates to the platform', () {
      when(platform.stateChanges)
          .thenAnswer((_) => Stream.value(CaptureState.capturing));

      expect(
        const EarshotCapture().stateChanges(),
        emits(CaptureState.capturing),
      );
      verify(platform.stateChanges).called(1);
    });
  });

  group(MicrophonePermission, () {
    test('status delegates to the platform', () async {
      when(platform.microphonePermissionStatus)
          .thenAnswer((_) async => MicrophonePermissionStatus.granted);

      expect(
        await MicrophonePermission.status(),
        MicrophonePermissionStatus.granted,
      );
      verify(platform.microphonePermissionStatus).called(1);
    });

    test('request delegates to the platform', () async {
      when(platform.requestMicrophonePermission)
          .thenAnswer((_) async => MicrophonePermissionStatus.denied);

      expect(
        await MicrophonePermission.request(),
        MicrophonePermissionStatus.denied,
      );
      verify(platform.requestMicrophonePermission).called(1);
    });
  });
}
