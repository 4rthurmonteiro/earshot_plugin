import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  group(SampleRate, () {
    test('exposes the rate in hertz', () {
      expect(SampleRate.hz16000.hz, 16000);
      expect(SampleRate.hz44100.hz, 44100);
      expect(SampleRate.hz48000.hz, 48000);
    });
  });

  group(CaptureConfig, () {
    test('defaults to 16 kHz', () {
      expect(const CaptureConfig().sampleRate, SampleRate.hz16000);
    });

    test('supports value equality', () {
      expect(
        const CaptureConfig(sampleRate: SampleRate.hz48000),
        const CaptureConfig(sampleRate: SampleRate.hz48000),
      );
      expect(
        const CaptureConfig(),
        isNot(const CaptureConfig(sampleRate: SampleRate.hz48000)),
      );
    });

    test('has a consistent hashCode', () {
      expect(
        const CaptureConfig(sampleRate: SampleRate.hz44100).hashCode,
        const CaptureConfig(sampleRate: SampleRate.hz44100).hashCode,
      );
    });

    test('has a readable toString', () {
      expect(
        const CaptureConfig().toString(),
        'CaptureConfig(sampleRate: SampleRate.hz16000)',
      );
    });
  });

  group(PcmChunk, () {
    PcmChunk chunk({
      List<double> samples = const [0.1, -0.2, 0.3],
      SampleRate sampleRate = SampleRate.hz16000,
      Duration timestamp = const Duration(milliseconds: 100),
    }) => PcmChunk(
      samples: Float32List.fromList(samples),
      sampleRate: sampleRate,
      timestamp: timestamp,
    );

    test('supports value equality', () {
      final a = chunk();
      expect(a, a);
      expect(chunk(), chunk());
    });

    test('differs when any field differs', () {
      expect(chunk(), isNot(chunk(samples: [0.1, -0.2, 0.4])));
      expect(chunk(), isNot(chunk(samples: [0.1, -0.2])));
      expect(chunk(), isNot(chunk(sampleRate: SampleRate.hz48000)));
      expect(chunk(), isNot(chunk(timestamp: Duration.zero)));
      expect(chunk(), isNot(Object()));
    });

    test('has a consistent hashCode', () {
      expect(chunk().hashCode, chunk().hashCode);
    });

    test('has a readable toString', () {
      expect(
        chunk().toString(),
        'PcmChunk(samples: 3, sampleRate: SampleRate.hz16000, '
        'timestamp: 0:00:00.100000)',
      );
    });
  });
}
