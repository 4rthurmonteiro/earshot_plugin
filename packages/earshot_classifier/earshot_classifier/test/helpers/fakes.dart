import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_interpreter.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// The YAMNet index of each label used in tests.
int yamnetIndex(String label) =>
    const SoundVocabulary().labels(ClassifierBackend.yamnet).indexOf(label);

/// 521 scores, all zero except [scores].
Float32List yamnetScores([Map<String, double> scores = const {}]) {
  final result = Float32List(521);
  scores.forEach((label, score) => result[yamnetIndex(label)] = score);
  return result;
}

/// A [YamnetInterpreter] that answers each window with [scores], records the
/// windows it was given, and can be told to fail or to hold its answer.
class FakeYamnetInterpreter implements YamnetInterpreter {
  new({Float32List Function(int call)? scores})
    : scores = scores ?? ((_) => yamnetScores({'Bark': 0.9}));

  Float32List Function(int call) scores;
  final List<Float32List> windows = [];
  Error? runError;
  Completer<void>? gate;
  int closeCount = 0;

  @override
  Future<Float32List> run(Float32List waveform) async {
    windows.add(waveform);
    await gate?.future;
    if (runError != null) throw runError!;
    return scores(windows.length - 1);
  }

  @override
  Future<void> close() async => closeCount++;
}

/// Replaces [yamnetInterpreterLoader] with one that returns [interpreter],
/// and returns a function that restores it.
void Function() useFakeInterpreter(
  YamnetInterpreter interpreter, {
  Future<void>? ready,
  Error? error,
}) {
  final original = yamnetInterpreterLoader;
  yamnetInterpreterLoader = () async {
    await ready;
    if (error != null) throw error;
    return interpreter;
  };
  return () => yamnetInterpreterLoader = original;
}

/// [seconds] of a sine at [frequency] Hz and [rate], as one chunk.
PcmChunk sineChunk({
  required SampleRate rate,
  double frequency = 1000,
  double seconds = 1,
  double amplitude = 0.5,
  Duration timestamp = Duration.zero,
}) {
  final samples = Float32List((rate.hz * seconds).round());
  for (var i = 0; i < samples.length; i++) {
    samples[i] = amplitude * math.sin(2 * math.pi * frequency * i / rate.hz);
  }
  return PcmChunk(samples: samples, sampleRate: rate, timestamp: timestamp);
}

/// [count] samples of silence at 16 kHz.
PcmChunk silentChunk(int count, {Duration timestamp = Duration.zero}) =>
    PcmChunk(
      samples: Float32List(count),
      sampleRate: SampleRate.hz16000,
      timestamp: timestamp,
    );

/// A capture platform whose PCM comes from [pcmController].
class FakeEarshotCapturePlatform extends EarshotCapturePlatform {
  new(this.pcmController);

  final StreamController<PcmChunk> pcmController;
  final List<CaptureConfig> configs = [];

  @override
  Stream<PcmChunk> pcm(CaptureConfig config) {
    configs.add(config);
    return pcmController.stream;
  }
}
