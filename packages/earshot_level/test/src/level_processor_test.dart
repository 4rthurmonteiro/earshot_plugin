import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:earshot_level/src/level_processor.dart';
import 'package:test/test.dart';

import '../helpers/signals.dart';

/// Feeds [samples] to [processor] in chunks and returns the last reading.
LevelReading _feed(
  LevelProcessor processor,
  Float32List samples, {
  SampleRate sampleRate = SampleRate.hz48000,
  int chunkSize = 1024,
  Duration start = Duration.zero,
}) {
  LevelReading? last;
  for (final chunk in chunked(
    samples,
    sampleRate: sampleRate,
    chunkSize: chunkSize,
    start: start,
  )) {
    last = processor.add(chunk) ?? last;
  }
  return last!;
}

Float32List _silence(SampleRate rate, double seconds) =>
    Float32List((rate.hz * seconds).round());

Float32List _tone(
  SampleRate rate,
  double seconds, {
  double hz = 1000,
  double amplitude = 1,
}) => sine(
  hz: hz,
  sampleRate: rate.hz,
  count: (rate.hz * seconds).round(),
  amplitude: amplitude,
);

void main() {
  group(LevelProcessor, () {
    test('exposes its options', () {
      const options = LevelOptions(weighting: Weighting.c);
      expect(LevelProcessor(options).options, options);
    });

    test('returns null for an empty chunk', () {
      final processor = LevelProcessor(const LevelOptions());
      expect(
        processor.add(
          PcmChunk(
            samples: Float32List(0),
            sampleRate: SampleRate.hz16000,
            timestamp: Duration.zero,
          ),
        ),
        isNull,
      );
    });

    test('reports the weighting and the time after the last sample', () {
      final processor = LevelProcessor(
        const LevelOptions(weighting: Weighting.z),
      );
      final reading = processor.add(
        PcmChunk(
          samples: Float32List(441),
          sampleRate: SampleRate.hz44100,
          timestamp: const Duration(seconds: 2),
        ),
      )!;
      expect(reading.weighting, Weighting.z);
      expect(reading.timestamp, const Duration(seconds: 2, milliseconds: 10));
    });

    group('levels', () {
      for (final rate in SampleRate.values) {
        for (final weighting in Weighting.values) {
          test('read 0 dB for a full-scale 1 kHz sine at ${rate.hz} Hz '
              'with $weighting', () {
            final processor = LevelProcessor(
              LevelOptions(weighting: weighting),
            );
            final reading = _feed(processor, _tone(rate, 2), sampleRate: rate);
            expect(reading.db, closeTo(0, 0.05));
            expect(reading.leq, closeTo(0, 0.05));
            expect(reading.leq1s, closeTo(0, 0.01));
            expect(reading.leq60s, closeTo(0, 0.05));
          });
        }
      }

      test('follow the A weighting of the tone frequency', () {
        final processor = LevelProcessor(const LevelOptions());
        // A-weighting at 125 Hz is -16.1 dB (IEC 61672-1).
        final reading = _feed(processor, _tone(SampleRate.hz48000, 2, hz: 125));
        expect(reading.leq1s, closeTo(-16.1, 0.5));
        expect(reading.db, closeTo(-16.1, 0.5));
      });

      test('scale with the amplitude', () {
        final processor = LevelProcessor(
          const LevelOptions(weighting: Weighting.z),
        );
        final reading = _feed(
          processor,
          _tone(SampleRate.hz48000, 1, amplitude: 0.1),
        );
        expect(reading.leq1s, closeTo(-20, 0.01));
      });

      test('read the floor for digital silence', () {
        for (final weighting in Weighting.values) {
          final processor = LevelProcessor(LevelOptions(weighting: weighting));
          final reading = _feed(
            processor,
            _silence(SampleRate.hz16000, 0.5),
            sampleRate: SampleRate.hz16000,
          );
          expect(reading.db, LevelReading.floorDb);
          expect(reading.leq, LevelReading.floorDb);
          expect(reading.leq1s, LevelReading.floorDb);
          expect(reading.leq60s, LevelReading.floorDb);
          expect(reading.db.isFinite, isTrue);
        }
      });

      test('add the calibration offset, including to the floor', () {
        const offset = 94.0;
        final processor = LevelProcessor(
          const LevelOptions(
            weighting: Weighting.z,
            calibration: Calibration(offsetDb: offset),
          ),
        );
        final loud = _feed(processor, _tone(SampleRate.hz48000, 1));
        expect(loud.db, closeTo(offset, 0.05));
        expect(loud.leq, closeTo(offset, 0.01));
        expect(loud.leq1s, closeTo(offset, 0.01));
        expect(loud.leq60s, closeTo(offset, 0.01));

        final quiet = _feed(
          LevelProcessor(
            const LevelOptions(calibration: Calibration(offsetDb: offset)),
          ),
          _silence(SampleRate.hz48000, 0.1),
        );
        expect(quiet.db, LevelReading.floorDb + offset);
      });
    });

    group('time weighting', () {
      // IEC 61672-1, Table 4: the response to a 4 kHz tone burst relative to
      // the steady response is 10·log10(1 - e^(-Tb/τ)).
      const bursts = <(Response, int, double)>[
        (Response.fast, 200, -1),
        (Response.fast, 50, -4.8),
        (Response.fast, 10, -11.1),
        (Response.slow, 500, -4.1),
        (Response.slow, 200, -7.4),
      ];
      for (final (response, millis, expected) in bursts) {
        test('$response reads $expected dB for a $millis ms tone burst', () {
          const rate = SampleRate.hz48000;
          double read(double seconds) => _feed(
            LevelProcessor(LevelOptions(response: response)),
            _tone(rate, seconds, hz: 4000),
            chunkSize: 48,
          ).db;
          final steady = read(10);
          expect(read(millis / 1000) - steady, closeTo(expected, 0.5));
        });
      }

      test('fast falls about 34.7 dB in the second after a tone stops', () {
        final processor = LevelProcessor(
          const LevelOptions(weighting: Weighting.z),
        );
        final before = _feed(processor, _tone(SampleRate.hz48000, 2));
        final after = _feed(processor, _silence(SampleRate.hz48000, 0.25));
        // 0.25 s at 34.7 dB/s.
        expect(before.db - after.db, closeTo(8.69, 0.1));
      });

      test('impulse holds a short burst longer than fast', () {
        double afterBurst(Response response) {
          final processor = LevelProcessor(
            LevelOptions(weighting: Weighting.z, response: response),
          );
          _feed(processor, _tone(SampleRate.hz48000, 0.1));
          return _feed(processor, _silence(SampleRate.hz48000, 0.5)).db;
        }

        expect(
          afterBurst(Response.impulse),
          greaterThan(afterBurst(Response.fast) + 10),
        );
      });
    });

    group('Leq', () {
      test('session Leq averages the energy of the whole session', () {
        final processor = LevelProcessor(
          const LevelOptions(weighting: Weighting.z),
        );
        _feed(processor, _tone(SampleRate.hz48000, 1));
        final reading = _feed(processor, _silence(SampleRate.hz48000, 1));
        expect(reading.leq, closeTo(-3.01, 0.01));
        expect(reading.leq60s, closeTo(-3.01, 0.01));
        expect(reading.leq1s, LevelReading.floorDb);
      });

      test('1 s Leq covers exactly the last second across partial bins', () {
        final processor = LevelProcessor(
          const LevelOptions(weighting: Weighting.z),
        );
        _feed(processor, _tone(SampleRate.hz48000, 1));
        // 0.5 s and 250 samples of silence: the reading lands mid-bin.
        final reading = _feed(processor, Float32List(24250), chunkSize: 970);
        const loudSeconds = 1 - 24250 / 48000;
        expect(reading.leq1s, closeTo(powerDb(loudSeconds), 0.001));
      });

      test('60 s Leq rolls over the last minute', () {
        const rate = SampleRate.hz16000;
        final processor = LevelProcessor(
          const LevelOptions(weighting: Weighting.z),
        );
        _feed(processor, _tone(rate, 60), sampleRate: rate, chunkSize: 1600);
        final reading = _feed(
          processor,
          _silence(rate, 30),
          sampleRate: rate,
          chunkSize: 1600,
        );
        expect(reading.leq60s, closeTo(-3.01, 0.01));
        expect(reading.leq, closeTo(powerDb(60 / 90), 0.01));
        expect(reading.leq1s, LevelReading.floorDb);
      });
    });

    test('gives the same reading whatever the chunk boundaries', () {
      final signal = _tone(SampleRate.hz44100, 1.3, hz: 440);
      LevelReading read(int chunkSize) => _feed(
        LevelProcessor(const LevelOptions()),
        signal,
        sampleRate: SampleRate.hz44100,
        chunkSize: chunkSize,
      );
      final reference = read(signal.length);
      for (final chunkSize in [1, 7, 441, 1000, 4096]) {
        final reading = read(chunkSize);
        expect(reading.db, closeTo(reference.db, 1e-9));
        expect(reading.leq, closeTo(reference.leq, 1e-9));
        expect(reading.leq1s, closeTo(reference.leq1s, 1e-9));
        expect(reading.leq60s, closeTo(reference.leq60s, 1e-9));
        expect(reading.timestamp, reference.timestamp);
      }
    });

    test('redesigns its filters when the sample rate changes', () {
      final processor = LevelProcessor(const LevelOptions());
      final first = _feed(processor, _tone(SampleRate.hz48000, 1, hz: 125));
      final second = _feed(
        processor,
        _tone(SampleRate.hz16000, 2, hz: 125),
        sampleRate: SampleRate.hz16000,
        start: const Duration(seconds: 1),
      );
      expect(first.leq1s, closeTo(-16.1, 0.5));
      expect(second.leq1s, closeTo(-16.1, 0.5));
      expect(second.db, closeTo(-16.1, 0.5));
      expect(second.leq, closeTo(-16.1, 0.5));
      expect(second.timestamp, const Duration(seconds: 3));
      expect(math.max(first.leq60s, second.leq60s), lessThan(-15));
    });
  });
}
