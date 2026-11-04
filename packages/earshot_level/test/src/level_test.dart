import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:test/test.dart';

void main() {
  group(Response, () {
    test('exposes the IEC 61672 time constants', () {
      expect(Response.fast.timeConstant, const Duration(milliseconds: 125));
      expect(Response.slow.timeConstant, const Duration(seconds: 1));
      expect(Response.impulse.timeConstant, const Duration(milliseconds: 35));
    });
  });

  group(Calibration, () {
    test('defaults to no offset', () {
      expect(const Calibration().offsetDb, 0);
    });

    test('supports value equality', () {
      expect(
        const Calibration(offsetDb: 1.5),
        const Calibration(offsetDb: 1.5),
      );
      expect(const Calibration(), isNot(const Calibration(offsetDb: 1.5)));
    });

    test('has a consistent hashCode', () {
      expect(
        const Calibration(offsetDb: 2).hashCode,
        const Calibration(offsetDb: 2).hashCode,
      );
    });

    test('has a readable toString', () {
      expect(
        const Calibration(offsetDb: 1.5).toString(),
        'Calibration(offsetDb: 1.5)',
      );
    });
  });

  group(LevelOptions, () {
    test('defaults to A weighting, fast response and no calibration', () {
      const options = LevelOptions();
      expect(options.weighting, Weighting.a);
      expect(options.response, Response.fast);
      expect(options.calibration, const Calibration());
    });

    test('supports value equality', () {
      expect(const LevelOptions(), const LevelOptions());
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(weighting: Weighting.z)),
      );
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(response: Response.slow)),
      );
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(calibration: Calibration(offsetDb: 1))),
      );
    });

    test('has a consistent hashCode', () {
      expect(const LevelOptions().hashCode, const LevelOptions().hashCode);
    });

    test('has a readable toString', () {
      expect(
        const LevelOptions().toString(),
        'LevelOptions(weighting: Weighting.a, response: Response.fast, '
        'calibration: Calibration(offsetDb: 0.0))',
      );
    });
  });

  group(LevelReading, () {
    LevelReading reading({
      double db = 60,
      double leq = 55,
      Weighting weighting = Weighting.a,
      Duration timestamp = const Duration(seconds: 1),
    }) => LevelReading(
      db: db,
      leq: leq,
      weighting: weighting,
      timestamp: timestamp,
    );

    test('supports value equality', () {
      expect(reading(), reading());
      expect(reading(), isNot(reading(db: 61)));
      expect(reading(), isNot(reading(leq: 56)));
      expect(reading(), isNot(reading(weighting: Weighting.c)));
      expect(reading(), isNot(reading(timestamp: Duration.zero)));
    });

    test('has a consistent hashCode', () {
      expect(reading().hashCode, reading().hashCode);
    });

    test('has a readable toString', () {
      expect(
        reading().toString(),
        'LevelReading(db: 60.0, leq: 55.0, weighting: Weighting.a, '
        'timestamp: 0:00:01.000000)',
      );
    });
  });

  group(LevelMeter, () {
    test('defaults to the default options', () {
      expect(const LevelMeter().options, const LevelOptions());
    });

    test('returns a stream that errors and does not throw', () {
      final pcm = Stream.value(
        PcmChunk(
          samples: Float32List(4),
          sampleRate: SampleRate.hz16000,
          timestamp: Duration.zero,
        ),
      );
      expect(
        pcm.transform(const LevelMeter()),
        emitsError(isA<UnimplementedError>()),
      );
    });
  });
}
