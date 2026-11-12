import 'package:earshot_example/yamnet_benchmark.dart';
import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotClassifier extends Mock implements EarshotClassifier;

SoundDetection _detection(int window, {String label = 'Speech'}) =>
    SoundDetection(
      group: SoundGroup.people,
      rawLabel: label,
      confidence: 0.9,
      backend: ClassifierBackend.yamnet,
      timestamp: Duration(milliseconds: 487 * window),
    );

Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

void main() {
  setUpAll(() => registerFallbackValue(const Stream<PcmChunk>.empty()));

  group('YamnetBenchmarkResult', () {
    final result = YamnetBenchmarkResult(
      firstWindow: _ms(300),
      windowTimes: [for (var i = 1; i <= 20; i++) _ms(i)],
    );

    test('computes nearest-rank percentiles, max and mean', () {
      expect(result.p50, _ms(10));
      expect(result.p95, _ms(19));
      expect(result.max, _ms(20));
      expect(result.mean, const Duration(microseconds: 10500));
    });

    test('keeps the window times in order and unmodifiable', () {
      final unsorted = YamnetBenchmarkResult(
        firstWindow: Duration.zero,
        windowTimes: [_ms(3), _ms(1), _ms(2)],
      );
      expect(unsorted.windowTimes, [_ms(3), _ms(1), _ms(2)]);
      expect(unsorted.p50, _ms(2));
      expect(() => unsorted.windowTimes.add(_ms(4)), throwsUnsupportedError);
    });

    test('takes the only window as every percentile', () {
      final single = YamnetBenchmarkResult(
        firstWindow: Duration.zero,
        windowTimes: [_ms(7)],
      );
      expect(single.p50, _ms(7));
      expect(single.p95, _ms(7));
    });

    test('serializes to JSON in milliseconds', () {
      expect(result.toJson(), {
        'windows': 20,
        'firstWindowMs': 300.0,
        'p50Ms': 10.0,
        'p95Ms': 19.0,
        'maxMs': 20.0,
        'meanMs': 10.5,
      });
    });

    test('has a readable toString', () {
      expect(
        result.toString(),
        'YAMNet: 20 windows, p50 10.0 ms, p95 19.0 ms, max 20.0 ms, '
        'mean 10.5 ms, first window 300.0 ms',
      );
    });
  });

  group('benchmarkPcm', () {
    test('is long enough for the windows and deterministic', () {
      final pcm = benchmarkPcm(3);
      expect(pcm.length, 15600 + 2 * 7800);
      expect(pcm, benchmarkPcm(3));
      expect(pcm.every((sample) => sample.abs() <= 0.1), isTrue);
    });
  });

  group('runYamnetBenchmark', () {
    late EarshotClassifier classifier;

    setUp(() => classifier = _MockEarshotClassifier());

    Duration Function() clock(List<int> milliseconds) {
      final times = milliseconds.map(_ms).iterator;
      return () => (times..moveNext()).current;
    }

    test('measures the gap between windows after the warm-up', () async {
      when(() => classifier.classify(any())).thenAnswer(
        (_) => Stream.fromIterable([
          _detection(0),
          _detection(0, label: 'Conversation'),
          _detection(1),
          _detection(2),
          _detection(3),
        ]),
      );

      final result = await runYamnetBenchmark(
        classifier: classifier,
        windows: 4,
        warmUp: 1,
        elapsed: clock([500, 540, 570, 610]),
      );

      expect(result.firstWindow, _ms(500));
      expect(result.windowTimes, [_ms(30), _ms(40)]);
    });

    test('classifies 16 kHz noise for every window', () async {
      when(
        () => classifier.classify(any()),
      ).thenAnswer((_) => Stream.fromIterable([_detection(0), _detection(1)]));

      await runYamnetBenchmark(classifier: classifier, windows: 2, warmUp: 0);

      final pcm =
          verify(() => classifier.classify(captureAny())).captured.single
              as Stream<PcmChunk>;
      final chunk = await pcm.single;
      expect(chunk.sampleRate, SampleRate.hz16000);
      expect(chunk.samples, benchmarkPcm(2));
    });

    test('throws when a window yields no detection', () async {
      when(() => classifier.classify(any()))
          .thenAnswer((_) => Stream.value(_detection(0)));

      expect(
        runYamnetBenchmark(classifier: classifier, windows: 2),
        throwsStateError,
      );
    });

    test('defaults to YAMNet reporting every label', () {
      expect(kBenchmarkOptions.backend, ClassifierBackend.yamnet);
      expect(kBenchmarkOptions.minConfidence, 0);
      expect(kBenchmarkOptions.smoothing.hits, 1);
    });
  });
}
