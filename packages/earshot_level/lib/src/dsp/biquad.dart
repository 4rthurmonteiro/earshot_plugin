import 'dart:math' as math;

/// {@template biquad}
/// A second-order IIR section in transposed direct form II, in double
/// precision.
///
/// Internal to `earshot_level`.
/// {@endtemplate}
class Biquad {
  /// {@macro biquad}
  ///
  /// The coefficients are normalized so that `a0` is 1.
  new({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  /// The bilinear transform of the analog high-pass section
  /// `s² / ((s + ω1)(s + ω2))`, with poles at [pole1Hz] and [pole2Hz], for
  /// [sampleRate].
  ///
  /// Each pole is pre-warped, so its corner frequency is exact in the
  /// digital domain. Both poles must lie below the Nyquist frequency.
  factory highPass({
    required double pole1Hz,
    required double pole2Hz,
    required int sampleRate,
  }) {
    final k = 2.0 * sampleRate;
    final w1 = _prewarp(pole1Hz, k);
    final w2 = _prewarp(pole2Hz, k);
    // H(s) = s² / (s² + (w1 + w2) s + w1 w2), with s = k (1 - z⁻¹)/(1 + z⁻¹).
    final k2 = k * k;
    final sum = w1 + w2;
    final product = w1 * w2;
    final a0 = k2 + sum * k + product;
    return Biquad(
      b0: k2 / a0,
      b1: -2 * k2 / a0,
      b2: k2 / a0,
      a1: 2 * (product - k2) / a0,
      a2: (k2 - sum * k + product) / a0,
    );
  }

  static double _prewarp(double hz, double k) =>
      k * math.tan(math.pi * hz / (k / 2));

  /// The feed-forward coefficient of the current input.
  final double b0;

  /// The feed-forward coefficient of the previous input.
  final double b1;

  /// The feed-forward coefficient of the input before the previous one.
  final double b2;

  /// The feedback coefficient of the previous output.
  final double a1;

  /// The feedback coefficient of the output before the previous one.
  final double a2;

  double _z1 = 0;
  double _z2 = 0;

  /// Filters one sample.
  double process(double x) {
    final y = b0 * x + _z1;
    _z1 = b1 * x - a1 * y + _z2;
    _z2 = b2 * x - a2 * y;
    return y;
  }

  /// Clears the filter state, as if it had only seen silence.
  void reset() {
    _z1 = 0;
    _z2 = 0;
  }

  /// The magnitude of the frequency response at the normalized angular
  /// frequency [omega], in radians per sample.
  double magnitudeAt(double omega) {
    final c1 = math.cos(omega);
    final s1 = math.sin(omega);
    final c2 = math.cos(2 * omega);
    final s2 = math.sin(2 * omega);
    final numRe = b0 + b1 * c1 + b2 * c2;
    final numIm = -b1 * s1 - b2 * s2;
    final denRe = 1 + a1 * c1 + a2 * c2;
    final denIm = -a1 * s1 - a2 * s2;
    return math.sqrt(
      (numRe * numRe + numIm * numIm) / (denRe * denRe + denIm * denIm),
    );
  }
}
