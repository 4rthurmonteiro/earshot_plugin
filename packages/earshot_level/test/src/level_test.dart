import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:test/test.dart';

void main() {
  // Built at runtime so that equal values are not canonicalized consts.
  final offset = double.parse('1.5');

  group(TimeWeighting, () {
    test('exposes the IEC 61672 time constants', () {
      expect(
        TimeWeighting.fast.timeConstant,
        const Duration(milliseconds: 125),
      );
      expect(TimeWeighting.slow.timeConstant, const Duration(seconds: 1));
      expect(
        TimeWeighting.impulse.timeConstant,
        const Duration(milliseconds: 35),
      );
    });

    test('decays with the IEC 61672 time constants', () {
      expect(
        TimeWeighting.fast.decayTimeConstant,
        const Duration(milliseconds: 125),
      );
      expect(TimeWeighting.slow.decayTimeConstant, const Duration(seconds: 1));
      expect(
        TimeWeighting.impulse.decayTimeConstant,
        const Duration(milliseconds: 1500),
      );
    });
  });

  group(LevelCalibration, () {
    test('defaults to no offset', () {
      expect(const LevelCalibration().offsetDb, 0);
    });

    test('supports value equality', () {
      expect(
        const LevelCalibration(offsetDb: 1.5),
        const LevelCalibration(offsetDb: 1.5),
      );
      expect(
        const LevelCalibration(),
        isNot(const LevelCalibration(offsetDb: 1.5)),
      );
    });

    test('treats separately built equal values as equal', () {
      final a = LevelCalibration(offsetDb: offset);
      final b = LevelCalibration(offsetDb: offset);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const LevelCalibration()));
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const LevelCalibration(offsetDb: 1.5).toString(),
        'LevelCalibration(offsetDb: 1.5)',
      );
    });
  });

  group(LevelOptions, () {
    test('defaults to A weighting, fast response and no calibration', () {
      const options = LevelOptions();
      expect(options.weighting, FrequencyWeighting.a);
      expect(options.timeWeighting, TimeWeighting.fast);
      expect(options.calibration, const LevelCalibration());
    });

    test('supports value equality', () {
      expect(const LevelOptions(), const LevelOptions());
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(weighting: FrequencyWeighting.z)),
      );
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(timeWeighting: TimeWeighting.slow)),
      );
      expect(
        const LevelOptions(),
        isNot(const LevelOptions(calibration: LevelCalibration(offsetDb: 1))),
      );
    });

    test('treats separately built equal values as equal', () {
      final a = LevelOptions(calibration: LevelCalibration(offsetDb: offset));
      final b = LevelOptions(calibration: LevelCalibration(offsetDb: offset));
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const LevelOptions()));
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const LevelOptions().toString(),
        'LevelOptions(weighting: FrequencyWeighting.a, '
        'timeWeighting: TimeWeighting.fast, '
        'calibration: LevelCalibration(offsetDb: 0.0))',
      );
    });
  });

  group(LevelReading, () {
    LevelReading reading({
      double db = 60,
      double leq = 55,
      double leq1s = 58,
      double leq60s = 57,
      FrequencyWeighting weighting = FrequencyWeighting.a,
      Duration timestamp = const Duration(seconds: 1),
    }) => LevelReading(
      db: db,
      leq: leq,
      leq1s: leq1s,
      leq60s: leq60s,
      weighting: weighting,
      timestamp: timestamp,
    );

    test('supports value equality', () {
      expect(reading(), reading());
      expect(reading(), isNot(reading(db: 61)));
      expect(reading(), isNot(reading(leq: 56)));
      expect(reading(), isNot(reading(leq1s: 56)));
      expect(reading(), isNot(reading(leq60s: 56)));
      expect(reading(), isNot(reading(weighting: FrequencyWeighting.c)));
      expect(reading(), isNot(reading(timestamp: Duration.zero)));
    });

    test('has a consistent hashCode', () {
      expect(reading().hashCode, reading().hashCode);
    });

    test('has a readable toString', () {
      expect(
        reading().toString(),
        'LevelReading(db: 60.0, leq: 55.0, leq1s: 58.0, leq60s: 57.0, '
        'weighting: FrequencyWeighting.a, timestamp: 0:00:01.000000)',
      );
    });
  });

  group(LevelMeter, () {
    test('defaults to the default options', () {
      expect(const LevelMeter().options, const LevelOptions());
    });

    PcmChunk chunk(int length, {Duration timestamp = Duration.zero}) =>
        PcmChunk(
          samples: Float32List(length),
          sampleRate: SampleRate.hz16000,
          timestamp: timestamp,
        );

    test('emits one reading per non-empty chunk', () async {
      final pcm = Stream.fromIterable([
        chunk(160),
        chunk(0),
        chunk(160, timestamp: const Duration(milliseconds: 10)),
      ]);
      final readings = await pcm.transform(const LevelMeter()).toList();
      expect(readings, hasLength(2));
      expect(readings.map((r) => r.timestamp), const [
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
      ]);
      expect(readings.first.db, LevelReading.floorDb);
    });

    test('measures with its options', () async {
      const meter = LevelMeter(
        options: LevelOptions(
          weighting: FrequencyWeighting.c,
          calibration: LevelCalibration(offsetDb: 30),
        ),
      );
      final reading = await Stream.value(chunk(160)).transform(meter).single;
      expect(reading.weighting, FrequencyWeighting.c);
      expect(reading.db, LevelReading.floorDb + 30);
    });

    test('forwards errors and keeps measuring', () async {
      final controller = StreamController<PcmChunk>();
      final events = controller.stream.transform(const LevelMeter());
      final expectation = expectLater(
        events,
        emitsInOrder([
          emitsError(isA<StateError>()),
          isA<LevelReading>(),
          emitsDone,
        ]),
      );
      controller
        ..addError(StateError('mic'))
        ..add(chunk(16));
      await controller.close();
      await expectation;
    });

    test('starts a new session for each listen', () async {
      final source = Stream<PcmChunk>.multi((controller) {
        controller.add(chunk(16));
        unawaited(controller.close());
      });
      final stream = source.transform(const LevelMeter());
      final first = await stream.single;
      final second = await stream.single;
      expect(second, first);
    });

    test('pauses, resumes and cancels the PCM subscription', () async {
      var paused = false;
      var cancelled = false;
      final controller = StreamController<PcmChunk>(
        onPause: () => paused = true,
        onResume: () => paused = false,
        onCancel: () => cancelled = true,
      );
      final subscription = controller.stream
          .transform(const LevelMeter())
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      subscription.pause();
      await Future<void>.delayed(Duration.zero);
      expect(paused, isTrue);
      subscription.resume();
      await Future<void>.delayed(Duration.zero);
      expect(paused, isFalse);
      await subscription.cancel();
      expect(cancelled, isTrue);
    });
  });
}
