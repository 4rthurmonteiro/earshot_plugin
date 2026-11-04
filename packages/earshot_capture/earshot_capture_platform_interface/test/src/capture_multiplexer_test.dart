import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:test/test.dart';

NativePcm _pcm(List<double> samples, int millis) => (
  samples: Float32List.fromList(samples),
  timestamp: Duration(milliseconds: millis),
);

void main() {
  group(CaptureMultiplexer, () {
    late StreamController<NativePcm> nativePcm;
    late StreamController<CaptureState> nativeStates;
    late List<CaptureConfig> starts;
    late int stops;
    late Future<void> Function(CaptureConfig) onStart;
    late Future<void> Function() onStop;
    late CaptureMultiplexer multiplexer;

    const config16k = CaptureConfig();
    const config48k = CaptureConfig(sampleRate: SampleRate.hz48000);

    setUp(() {
      nativePcm = StreamController.broadcast();
      nativeStates = StreamController.broadcast();
      starts = [];
      stops = 0;
      onStart = (_) async {};
      onStop = () async {};
      multiplexer = CaptureMultiplexer(
        start: (config) {
          starts.add(config);
          return onStart(config);
        },
        stop: () {
          stops++;
          return onStop();
        },
        nativePcm: nativePcm.stream,
        nativeStates: nativeStates.stream,
      );
    });

    test('starts idle', () {
      expect(multiplexer.state, CaptureState.idle);
    });

    test(
      'starts native capture on the first listen and delivers PCM',
      () async {
        final chunks = <PcmChunk>[];
        final subscription = multiplexer.pcm(config48k).listen(chunks.add);
        await pumpEventQueue();

        expect(starts, [config48k]);
        expect(nativePcm.hasListener, isTrue);
        expect(nativeStates.hasListener, isTrue);
        expect(multiplexer.state, CaptureState.capturing);

        nativePcm
          ..add(_pcm([0.5, -0.5], 1000))
          ..add(_pcm([0.25], 1100));
        await pumpEventQueue();

        expect(chunks, [
          PcmChunk(
            samples: Float32List.fromList([0.5, -0.5]),
            sampleRate: SampleRate.hz48000,
            timestamp: Duration.zero,
          ),
          PcmChunk(
            samples: Float32List.fromList([0.25]),
            sampleRate: SampleRate.hz48000,
            timestamp: const Duration(milliseconds: 100),
          ),
        ]);

        await subscription.cancel();
        await pumpEventQueue();
        expect(stops, 1);
        expect(nativePcm.hasListener, isFalse);
        expect(nativeStates.hasListener, isFalse);
        expect(multiplexer.state, CaptureState.idle);
      },
    );

    test('shares the session between subscriptions at the same rate', () async {
      final first = <PcmChunk>[];
      final second = <PcmChunk>[];
      final a = multiplexer.pcm(config16k).listen(first.add);
      await pumpEventQueue();
      nativePcm.add(_pcm([0.1], 0));
      await pumpEventQueue();

      final b = multiplexer.pcm(config16k).listen(second.add);
      await pumpEventQueue();
      nativePcm.add(_pcm([0.2], 500));
      await pumpEventQueue();

      expect(starts, [config16k]);
      expect(first.map((chunk) => chunk.timestamp), [
        Duration.zero,
        const Duration(milliseconds: 500),
      ]);
      expect(second.single.timestamp, Duration.zero);
      expect(second.single.samples, first.last.samples);
      expect(identical(second.single.samples, first.last.samples), isFalse);

      await a.cancel();
      await pumpEventQueue();
      expect(stops, 0, reason: 'b is still listening');

      await b.cancel();
      await pumpEventQueue();
      expect(stops, 1);
    });

    test('rejects a subscription at a different rate', () async {
      final a = multiplexer.pcm(config16k).listen((_) {});
      await pumpEventQueue();

      await expectLater(
        multiplexer.pcm(config48k),
        emitsInOrder([
          emitsError(
            isA<CaptureException>().having(
              (error) => error.code,
              'code',
              CaptureErrorCode.sampleRateConflict,
            ),
          ),
          emitsDone,
        ]),
      );
      expect(starts, [config16k]);
      expect(stops, 0);

      await a.cancel();
    });

    test('fails every subscription when start fails', () async {
      const error = CaptureException(CaptureErrorCode.permissionDenied);
      onStart = (_) => Future.error(error);

      await expectLater(
        multiplexer.pcm(config16k),
        emitsInOrder([emitsError(error), emitsDone]),
      );
      await pumpEventQueue();
      expect(stops, 1);
      expect(multiplexer.state, CaptureState.idle);
    });

    test('ignores a start failure once the subscription is gone', () async {
      final start = Completer<void>();
      onStart = (_) => start.future;
      final errors = <Object>[];

      final subscription = multiplexer
          .pcm(config16k)
          .listen((_) {}, onError: errors.add);
      await pumpEventQueue();
      // The cancel completes once stop has run, which waits for start.
      final cancelled = subscription.cancel();
      start.completeError(const CaptureException(CaptureErrorCode.unknown));
      await cancelled;
      await pumpEventQueue();

      expect(errors, isEmpty);
      expect(stops, 1);
      expect(multiplexer.state, CaptureState.idle);
    });

    test('runs stop after a pending start', () async {
      final start = Completer<void>();
      onStart = (_) => start.future;

      final subscription = multiplexer.pcm(config16k).listen((_) {});
      await pumpEventQueue();
      unawaited(subscription.cancel());
      await pumpEventQueue();
      expect(stops, 0);

      start.complete();
      await pumpEventQueue();
      expect(stops, 1);
      expect(multiplexer.state, CaptureState.idle);
    });

    test('fails every subscription on a native PCM error', () async {
      const error = CaptureException(CaptureErrorCode.audioUnavailable);
      final a = multiplexer.pcm(config16k);
      final b = multiplexer.pcm(config16k);
      final expectations = [
        expectLater(a, emitsInOrder([emitsError(error), emitsDone])),
        expectLater(b, emitsInOrder([emitsError(error), emitsDone])),
      ];
      await pumpEventQueue();

      nativePcm.addError(error);
      await Future.wait(expectations);
      await pumpEventQueue();
      expect(stops, 1);
    });

    test('closes every subscription when native PCM ends', () async {
      final done = expectLater(multiplexer.pcm(config16k), emitsDone);
      await pumpEventQueue();

      await nativePcm.close();
      await done;
      await pumpEventQueue();
      expect(stops, 1);
    });

    test('swallows stop failures', () async {
      onStop = () => Future.error(StateError('gone'));

      final subscription = multiplexer.pcm(config16k).listen((_) {});
      await pumpEventQueue();
      await subscription.cancel();
      await pumpEventQueue();

      expect(stops, 1);
      expect(multiplexer.state, CaptureState.idle);
    });

    test('can start again after stopping', () async {
      final first = multiplexer.pcm(config16k).listen((_) {});
      await pumpEventQueue();
      await first.cancel();
      await pumpEventQueue();

      final second = multiplexer.pcm(config48k).listen((_) {});
      await pumpEventQueue();
      expect(starts, [config16k, config48k]);
      await second.cancel();
      await pumpEventQueue();
      expect(stops, 2);
    });

    group('stateChanges', () {
      test('emits the current state first, then changes', () async {
        final states = <CaptureState>[];
        final listener = multiplexer.stateChanges().listen(states.add);

        final subscription = multiplexer.pcm(config16k).listen((_) {});
        await pumpEventQueue();
        nativeStates
          ..add(CaptureState.interrupted)
          ..add(CaptureState.interrupted)
          ..add(CaptureState.idle)
          ..addError(StateError('ignored'))
          ..add(CaptureState.capturing);
        await pumpEventQueue();
        await subscription.cancel();
        await pumpEventQueue();

        expect(states, [
          CaptureState.idle,
          CaptureState.capturing,
          CaptureState.interrupted,
          CaptureState.capturing,
          CaptureState.idle,
        ]);
        await listener.cancel();
      });

      test('keeps a state the host reported before start returned', () async {
        final start = Completer<void>();
        onStart = (_) => start.future;

        final subscription = multiplexer.pcm(config16k).listen((_) {});
        await pumpEventQueue();
        nativeStates.add(CaptureState.interrupted);
        await pumpEventQueue();
        start.complete();
        await pumpEventQueue();

        expect(multiplexer.state, CaptureState.interrupted);
        await subscription.cancel();
      });

      test('starts with the current state for late listeners', () async {
        final subscription = multiplexer.pcm(config16k).listen((_) {});
        await pumpEventQueue();

        await expectLater(
          multiplexer.stateChanges(),
          emits(CaptureState.capturing),
        );
        await subscription.cancel();
      });
    });
  });
}
