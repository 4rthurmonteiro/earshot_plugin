import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';

/// Converts a linear amplitude ratio to decibels.
double amplitudeDb(double ratio) => 20 * math.log(ratio) / math.ln10;

/// Converts a power ratio to decibels.
double powerDb(double ratio) => 10 * math.log(ratio) / math.ln10;

/// The exact IEC 61672-1 frequency for a nominal one-third-octave band:
/// 1000 · 10^(n/10) Hz.
double bandHz(int n) => 1000 * math.pow(10, n / 10).toDouble();

/// A sine of [hz] with [amplitude], [count] samples long, starting at sample
/// [offset] (so consecutive calls continue the same phase).
Float32List sine({
  required double hz,
  required int sampleRate,
  required int count,
  double amplitude = 1,
  int offset = 0,
}) {
  final samples = Float32List(count);
  final step = 2 * math.pi * hz / sampleRate;
  for (var i = 0; i < count; i++) {
    samples[i] = amplitude * math.sin(step * (offset + i));
  }
  return samples;
}

/// Splits [samples] into chunks of [chunkSize] at [sampleRate], with
/// timestamps starting at [start].
List<PcmChunk> chunked(
  Float32List samples, {
  required SampleRate sampleRate,
  required int chunkSize,
  Duration start = Duration.zero,
}) {
  final chunks = <PcmChunk>[];
  for (var i = 0; i < samples.length; i += chunkSize) {
    final end = math.min(i + chunkSize, samples.length);
    chunks.add(
      PcmChunk(
        samples: Float32List.sublistView(samples, i, end),
        sampleRate: sampleRate,
        timestamp:
            start +
            Duration(
              microseconds: (i * Duration.microsecondsPerSecond / sampleRate.hz)
                  .round(),
            ),
      ),
    );
  }
  return chunks;
}
