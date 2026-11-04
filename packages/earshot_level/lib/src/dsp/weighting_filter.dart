import 'dart:math' as math;

import 'package:earshot_level/src/dsp/biquad.dart';
import 'package:earshot_level/src/dsp/linear_phase_fir.dart';
import 'package:earshot_level/src/weighting.dart';

/// The pole frequencies of the IEC 61672-1 weighting functions, in hertz.
const _f1 = 20.598997;
const _f2 = 107.65265;
const _f3 = 737.86223;
const _f4 = 12194.217;

/// {@template weighting_filter}
/// A digital frequency-weighting filter for one sample rate, as defined by
/// IEC 61672-1.
///
/// Internal to `earshot_level`. The analog weighting functions are split in
/// two:
///
/// - the low-frequency poles (20.6 Hz, and for A-weighting also 107.7 Hz
///   and 737.9 Hz) with their zeros at 0 Hz, mapped to biquads with the
///   pre-warped bilinear transform;
/// - the double pole at 12.2 kHz, which lies close to or above the Nyquist
///   frequency, where the bilinear transform would compress it. It is
///   modelled by a linear-phase FIR fitted to the analog magnitude up to the
///   Nyquist frequency.
///
/// The gain is normalized to 0 dB at 1 kHz. [Weighting.z] passes the signal
/// through unchanged.
/// {@endtemplate}
class WeightingFilter {
  /// {@macro weighting_filter}
  new(this.weighting, this.sampleRate)
    : _sections = _sectionsFor(weighting, sampleRate),
      _highPoles = weighting == Weighting.z ? null : _highPolesFor(sampleRate) {
    _gain = 1 / _rawMagnitudeAt(1000);
  }

  /// The frequency weighting this filter applies.
  final Weighting weighting;

  /// The sample rate this filter is designed for, in hertz.
  final int sampleRate;

  final List<Biquad> _sections;
  final LinearPhaseFir? _highPoles;
  late final double _gain;

  static List<Biquad> _sectionsFor(Weighting weighting, int sampleRate) =>
      switch (weighting) {
        Weighting.a => [
          Biquad.highPass(pole1Hz: _f1, pole2Hz: _f1, sampleRate: sampleRate),
          Biquad.highPass(pole1Hz: _f2, pole2Hz: _f3, sampleRate: sampleRate),
        ],
        Weighting.c => [
          Biquad.highPass(pole1Hz: _f1, pole2Hz: _f1, sampleRate: sampleRate),
        ],
        Weighting.z => const [],
      };

  static LinearPhaseFir _highPolesFor(int sampleRate) => LinearPhaseFir.fit(
    // |ω4² / (s + ω4)²| = 1 / (1 + (f / f4)²).
    target: (omega) {
      final ratio = omega * sampleRate / (2 * math.pi * _f4);
      return 1 / (1 + ratio * ratio);
    },
  );

  /// Filters one sample.
  double process(double x) {
    var y = x;
    for (final section in _sections) {
      y = section.process(y);
    }
    final highPoles = _highPoles;
    if (highPoles != null) y = highPoles.process(y);
    return y * _gain;
  }

  /// Clears the filter state, as if it had only seen silence.
  void reset() {
    for (final section in _sections) {
      section.reset();
    }
    _highPoles?.reset();
  }

  /// The magnitude of the frequency response at [hz], as a linear gain.
  double magnitudeAt(double hz) => _rawMagnitudeAt(hz) * _gain;

  double _rawMagnitudeAt(double hz) {
    final omega = 2 * math.pi * hz / sampleRate;
    var magnitude = _highPoles?.magnitudeAt(omega) ?? 1.0;
    for (final section in _sections) {
      magnitude *= section.magnitudeAt(omega);
    }
    return magnitude;
  }
}
