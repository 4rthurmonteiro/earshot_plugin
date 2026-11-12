import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_plugin/earshot_plugin.dart';

/// How many YAMNet windows the benchmark classifies.
const kBenchmarkWindows = 120;

/// How many window times at the start of the run are left out of the
/// statistics, while the model and the isolate warm up.
const kBenchmarkWarmUpWindows = 5;

/// The classifier options of the benchmark: YAMNet on every platform, and
/// every label reported, so that each window yields detections.
const kBenchmarkOptions = ClassifierOptions(
  backend: ClassifierBackend.yamnet,
  minConfidence: 0,
  smoothing: Smoothing(hits: 1),
);

const _windowLength = 15600;
const _hopLength = 7800;

/// {@template yamnet_benchmark_result}
/// How long YAMNet took to classify each window of a benchmark run.
/// {@endtemplate}
class YamnetBenchmarkResult {
  /// {@macro yamnet_benchmark_result}
  ///
  /// [windowTimes] must not be empty.
  new({required this.firstWindow, required List<Duration> windowTimes})
    : windowTimes = List.unmodifiable(windowTimes),
      _sorted = List.of(windowTimes)..sort();

  /// The time from the start of the run to the detections of the first
  /// window: loading the model plus one inference.
  final Duration firstWindow;

  /// The time each window took after the warm-up, in order: the gap between
  /// the detections of one window and those of the next.
  final List<Duration> windowTimes;

  final List<Duration> _sorted;

  /// The median window time.
  Duration get p50 => _percentile(0.5);

  /// The 95th percentile window time.
  Duration get p95 => _percentile(0.95);

  /// The longest window time.
  Duration get max => _sorted.last;

  /// The mean window time.
  Duration get mean =>
      windowTimes.reduce((a, b) => a + b) ~/ windowTimes.length;

  /// The nearest-rank percentile [p], between 0 and 1.
  Duration _percentile(double p) =>
      _sorted[math.max((p * _sorted.length).ceil() - 1, 0)];

  /// The result as JSON, in milliseconds.
  Map<String, Object> toJson() => {
    'windows': windowTimes.length,
    'firstWindowMs': _ms(firstWindow),
    'p50Ms': _ms(p50),
    'p95Ms': _ms(p95),
    'maxMs': _ms(max),
    'meanMs': _ms(mean),
  };

  static double _ms(Duration duration) => duration.inMicroseconds / 1000;

  @override
  String toString() =>
      'YAMNet: ${windowTimes.length} windows, '
      'p50 ${_ms(p50)} ms, p95 ${_ms(p95)} ms, max ${_ms(max)} ms, '
      'mean ${_ms(mean)} ms, first window ${_ms(firstWindow)} ms';
}

/// Deterministic white noise long enough for [windows] YAMNet windows at
/// 16 kHz.
Float32List benchmarkPcm(int windows) {
  final random = math.Random(42);
  return Float32List.fromList([
    for (var i = 0; i < _windowLength + (windows - 1) * _hopLength; i++)
      (random.nextDouble() * 2 - 1) * 0.1,
  ]);
}

/// Classifies [windows] windows of noise with [classifier] as fast as it
/// can, and measures how long each window takes.
///
/// All the PCM is queued at once, so the classifier is never waiting for
/// audio: the gap between the detections of two windows is the time one
/// window took. The first [warmUp] gaps are left out. [elapsed] reads the
/// time since the start of the run, and defaults to a [Stopwatch].
///
/// Throws a [StateError] if a window yields no detection, because the gaps
/// would then span two windows.
Future<YamnetBenchmarkResult> runYamnetBenchmark({
  EarshotClassifier classifier = const EarshotClassifier(
    options: kBenchmarkOptions,
  ),
  int windows = kBenchmarkWindows,
  int warmUp = kBenchmarkWarmUpWindows,
  Duration Function()? elapsed,
}) async {
  final pcm = PcmChunk(
    samples: benchmarkPcm(windows),
    sampleRate: SampleRate.hz16000,
    timestamp: Duration.zero,
  );
  final stopwatch = Stopwatch()..start();
  final now = elapsed ?? () => stopwatch.elapsed;

  final arrivals = <Duration>[];
  Duration? lastWindow;
  await for (final detection in classifier.classify(Stream.value(pcm))) {
    if (detection.timestamp == lastWindow) continue;
    lastWindow = detection.timestamp;
    arrivals.add(now());
  }
  if (arrivals.length != windows) {
    throw StateError(
      'Expected detections for $windows windows, got ${arrivals.length}.',
    );
  }
  return YamnetBenchmarkResult(
    firstWindow: arrivals.first,
    windowTimes: [
      for (var i = warmUp + 1; i < arrivals.length; i++)
        arrivals[i] - arrivals[i - 1],
    ],
  );
}
