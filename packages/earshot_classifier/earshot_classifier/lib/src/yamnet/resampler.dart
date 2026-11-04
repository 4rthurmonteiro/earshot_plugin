import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// {@template resampler}
/// A streaming windowed-sinc resampler with exact rational polyphase
/// filters.
///
/// Converts mono PCM from [inputRate] to [outputRate]. For 48 kHz → 16 kHz
/// the ratio is 1/3 and a single filter phase is used; for 44.1 kHz → 16 kHz
/// the ratio is 160/441 and 160 phases are precomputed.
///
/// The low-pass filter is a Blackman-windowed sinc with [zeroCrossings] zero
/// crossings on each side, cut off at 95% of the lower Nyquist frequency.
/// Its DC gain is 1 for every phase.
///
/// State carries over between calls to [process], so a signal split into
/// chunks resamples to the same output as in one piece. Samples before the
/// first chunk are treated as silence.
/// {@endtemplate}
@internal
class Resampler {
  /// {@macro resampler}
  new({
    required this.inputRate,
    required this.outputRate,
    this.zeroCrossings = 16,
  }) {
    final divisor = inputRate.gcd(outputRate);
    _up = outputRate ~/ divisor;
    _down = inputRate ~/ divisor;
    // Cutoff in cycles per input sample.
    final cutoff = 0.5 * math.min(1.0, outputRate / inputRate) * 0.95;
    _halfWidth = (zeroCrossings / (2 * cutoff)).ceil();
    _phases = List.generate(_up, (phase) {
      final fraction = phase / _up;
      final taps = Float64List(2 * _halfWidth);
      var sum = 0.0;
      for (var j = 0; j < taps.length; j++) {
        final t = j - _halfWidth + 1 - fraction;
        final value = _sinc(2 * cutoff * t) * _blackman(t / _halfWidth);
        taps[j] = value;
        sum += value;
      }
      for (var j = 0; j < taps.length; j++) {
        taps[j] /= sum;
      }
      return taps;
    });
  }

  /// The rate of the PCM passed to [process], in Hz.
  final int inputRate;

  /// The rate of the PCM [process] returns, in Hz.
  final int outputRate;

  /// The number of zero crossings of the sinc on each side of the filter.
  final int zeroCrossings;

  late final int _up;
  late final int _down;
  late final int _halfWidth;
  late final List<Float64List> _phases;

  // Input samples still needed, starting at absolute input index _offset.
  final List<double> _history = [];
  int _offset = 0;
  // The absolute index of the next output sample.
  int _next = 0;

  /// Resamples the next [input] samples and returns every output sample that
  /// can be computed so far.
  Float32List process(Float32List input) {
    _history.addAll(input);
    final end = _offset + _history.length;
    final output = <double>[];
    while (true) {
      final position = _next * _down;
      final center = position ~/ _up;
      if (center + _halfWidth >= end) break;
      final taps = _phases[position % _up];
      final first = center - _halfWidth + 1;
      var sum = 0.0;
      for (var j = 0; j < taps.length; j++) {
        final index = first + j;
        if (index >= 0) sum += taps[j] * _history[index - _offset];
      }
      output.add(sum);
      _next++;
    }
    // The loop stops before the next center's window runs past the input, so
    // keepFrom always lies within the history.
    final keepFrom = (_next * _down) ~/ _up - _halfWidth + 1;
    if (keepFrom > _offset) {
      _history.removeRange(0, keepFrom - _offset);
      _offset = keepFrom;
    }
    return Float32List.fromList(output);
  }

  static double _sinc(double x) {
    if (x == 0) return 1;
    final px = math.pi * x;
    return math.sin(px) / px;
  }

  static double _blackman(double x) =>
      0.42 + 0.5 * math.cos(math.pi * x) + 0.08 * math.cos(2 * math.pi * x);
}
