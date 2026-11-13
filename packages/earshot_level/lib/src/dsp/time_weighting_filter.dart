import 'dart:math' as math;

import 'package:earshot_level/src/time_weighting.dart';

/// {@template time_weighting_filter}
/// An exponential time weighting of the squared signal, as defined by
/// IEC 61672-1.
///
/// Internal to `earshot_level`. The output is a running mean square that
/// rises with [TimeWeighting.timeConstant] and decays with
/// [TimeWeighting.decayTimeConstant]. It starts at 0, as if the meter had only
/// heard silence.
/// {@endtemplate}
class TimeWeightingFilter {
  /// {@macro time_weighting_filter}
  new(TimeWeighting timeWeighting, int sampleRate)
    : _rise = _coefficient(timeWeighting.timeConstant, sampleRate),
      _decay = _coefficient(timeWeighting.decayTimeConstant, sampleRate);

  static double _coefficient(Duration timeConstant, int sampleRate) {
    final seconds =
        timeConstant.inMicroseconds / Duration.microsecondsPerSecond;
    return 1 - math.exp(-1 / (seconds * sampleRate));
  }

  final double _rise;
  final double _decay;

  /// The current time-weighted mean square.
  double meanSquare = 0;

  /// Adds one squared sample and returns the updated mean square.
  double add(double square) {
    final coefficient = square > meanSquare ? _rise : _decay;
    return meanSquare += (square - meanSquare) * coefficient;
  }
}
