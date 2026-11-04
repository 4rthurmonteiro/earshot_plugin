import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_framer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

/// [count] samples at 16 kHz whose values are their absolute indices.
PcmChunk _ramp(int start, int count) => PcmChunk(
  samples: Float32List.fromList([
    for (var i = 0; i < count; i++) (start + i).toDouble(),
  ]),
  sampleRate: SampleRate.hz16000,
  timestamp: const Duration(seconds: 5),
);

void main() {
  group(YamnetFramer, () {
    test('emits 0.975 s windows with a 50% hop', () {
      final framer = YamnetFramer();
      final windows = <YamnetWindow>[];
      for (var start = 0; start < 32000; start += 1600) {
        windows.addAll(framer.add(_ramp(start, 1600)));
      }
      // Windows start at 0, 7800, 15600: the next one needs 39000 samples.
      expect(windows, hasLength(3));
      for (var i = 0; i < windows.length; i++) {
        final samples = windows[i].samples;
        expect(samples, hasLength(15600));
        expect(samples.first, i * 7800.0);
        expect(samples.last, i * 7800.0 + 15599);
      }
    });

    test('times windows from the first chunk', () {
      final framer = YamnetFramer();
      final windows = framer.add(_ramp(0, 32000));
      expect(windows.map((window) => window.timestamp), [
        const Duration(seconds: 5),
        const Duration(seconds: 5, microseconds: 487500),
        const Duration(seconds: 5, microseconds: 975000),
      ]);
    });

    test('resamples 48 kHz input to 16 kHz windows', () {
      final framer = YamnetFramer();
      final windows = framer.add(
        sineChunk(rate: SampleRate.hz48000, seconds: 2),
      );
      // 2 s at 16 kHz is 32000 samples, minus the resampler latency.
      expect(windows, hasLength(3));
    });

    test('follows a change of sample rate', () {
      final framer = YamnetFramer();
      expect(
        framer.add(sineChunk(rate: SampleRate.hz44100, seconds: 0.5)),
        isEmpty,
      );
      expect(framer.add(silentChunk(16000)), hasLength(2));
    });
  });
}
