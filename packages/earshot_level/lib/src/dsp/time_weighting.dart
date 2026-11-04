import 'dart:math' as math;

import 'package:earshot_level/src/response.dart';

/// {@template time_weighting}
/// An exponential time weighting of the squared signal, as defined by
/// IEC 61672-1.
///
/// Internal to `earshot_level`. The output is a running mean square that
/// rises with [Response.timeConstant] and decays with
/// [Response.decayTimeConstant]. It starts at 0, as if the meter had only
/// heard silence.
/// {@endtemplate}
class TimeWeighting {
  /// {@macro time_weighting}
  new(Response response, int sampleRate)
    : _rise = _coefficient(response.timeConstant, sampleRate),
      _decay = _coefficient(response.decayTimeConstant, sampleRate);

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
