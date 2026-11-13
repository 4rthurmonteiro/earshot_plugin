import 'dart:math' as math;

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:earshot_level/src/dsp/weighting_filter.dart';
import 'package:test/test.dart';

import '../../helpers/signals.dart';

/// IEC 61672-1:2013, Table 3: the design goals of the frequency weightings,
/// in decibels, keyed by the band index n of the exact frequency
/// 1000 · 10^(n/10) Hz.
const _iec = <int, ({String nominal, double a, double c})>{
  -15: (nominal: '31.5 Hz', a: -39.4, c: -3.0),
  -12: (nominal: '63 Hz', a: -26.2, c: -0.8),
  -9: (nominal: '125 Hz', a: -16.1, c: -0.2),
  -6: (nominal: '250 Hz', a: -8.6, c: 0),
  -3: (nominal: '500 Hz', a: -3.2, c: 0),
  0: (nominal: '1 kHz', a: 0, c: 0),
  3: (nominal: '2 kHz', a: 1.2, c: -0.2),
  6: (nominal: '4 kHz', a: 1, c: -0.8),
  7: (nominal: '5 kHz', a: 0.5, c: -1.3),
  8: (nominal: '6.3 kHz', a: -0.1, c: -2),
  9: (nominal: '8 kHz', a: -1.1, c: -3),
  12: (nominal: '16 kHz', a: -6.6, c: -8.5),
};

/// The ten bands tested at each rate. At 16 kHz, 8 kHz is the Nyquist
/// frequency and 16 kHz is above it, so 5 and 6.3 kHz take their place.
const _bands = <SampleRate, List<int>>{
  SampleRate.hz16000: [-15, -12, -9, -6, -3, 0, 3, 6, 7, 8],
  SampleRate.hz44100: [-15, -12, -9, -6, -3, 0, 3, 6, 9, 12],
  SampleRate.hz48000: [-15, -12, -9, -6, -3, 0, 3, 6, 9, 12],
};

/// The tolerance this package commits to against the IEC design goals.
const _tolerance = 0.5;

/// The analog IEC 61672-1 weighting, in decibels, normalized at 1 kHz.
double _analogDb(FrequencyWeighting weighting, double hz) {
  const f1 = 20.598997;
  const f2 = 107.65265;
  const f3 = 737.86223;
  const f4 = 12194.217;
  double magnitude(double f) {
    final ff = f * f;
    final low = ff / (ff + f1 * f1);
    final high = f4 * f4 / (ff + f4 * f4);
    return switch (weighting) {
      FrequencyWeighting.a =>
        low * high * ff / math.sqrt((ff + f2 * f2) * (ff + f3 * f3)),
      FrequencyWeighting.c => low * high,
      FrequencyWeighting.z => 1,
    };
  }

  return amplitudeDb(magnitude(hz) / magnitude(1000));
}

/// Measures the gain of [filter] for a sine of [hz], in decibels, from the
/// RMS of the output once the filter has settled.
double _measuredGainDb(WeightingFilter filter, double hz) {
  final rate = filter.sampleRate;
  final input = sine(hz: hz, sampleRate: rate, count: rate);
  final settle = rate ~/ 2;
  var inSum = 0.0;
  var outSum = 0.0;
  for (var i = 0; i < input.length; i++) {
    final y = filter.process(input[i]);
    if (i >= settle) {
      inSum += input[i] * input[i];
      outSum += y * y;
    }
  }
  return powerDb(outSum / inSum);
}

void main() {
  group(WeightingFilter, () {
    for (final rate in SampleRate.values) {
      group('at ${rate.hz} Hz', () {
        for (final weighting in FrequencyWeighting.values) {
          group('$weighting', () {
            for (final n in _bands[rate]!) {
              final band = _iec[n]!;
              final expected = switch (weighting) {
                FrequencyWeighting.a => band.a,
                FrequencyWeighting.c => band.c,
                FrequencyWeighting.z => 0.0,
              };
              test('is within ±$_tolerance dB of IEC 61672-1 at '
                  '${band.nominal} ($expected dB)', () {
                final filter = WeightingFilter(weighting, rate.hz);
                final hz = bandHz(n);
                expect(
                  _measuredGainDb(filter, hz),
                  closeTo(expected, _tolerance),
                );
                expect(
                  amplitudeDb(filter.magnitudeAt(hz)),
                  closeTo(expected, _tolerance),
                );
              });
            }

            test('follows the analog weighting within 0.15 dB from 10 Hz '
                'to 20 kHz or just below Nyquist', () {
              final filter = WeightingFilter(weighting, rate.hz);
              for (var n = -20; n <= 13; n++) {
                final hz = bandHz(n);
                if (hz > 0.995 * rate.hz / 2) continue;
                expect(
                  amplitudeDb(filter.magnitudeAt(hz)),
                  closeTo(_analogDb(weighting, hz), 0.15),
                  reason: '${hz.toStringAsFixed(1)} Hz',
                );
              }
            });
          });
        }
      });
    }

    test('exposes its weighting and sample rate', () {
      final filter = WeightingFilter(FrequencyWeighting.c, 44100);
      expect(filter.weighting, FrequencyWeighting.c);
      expect(filter.sampleRate, 44100);
    });

    test('reads exactly 0 dB at 1 kHz', () {
      for (final weighting in FrequencyWeighting.values) {
        expect(
          WeightingFilter(weighting, 48000).magnitudeAt(1000),
          closeTo(1, 1e-12),
        );
      }
    });

    test('passes the signal through unchanged with Z weighting', () {
      final filter = WeightingFilter(FrequencyWeighting.z, 16000);
      expect(filter.process(0.25), 0.25);
      expect(filter.process(-1), -1);
    });

    test('reset clears the state', () {
      for (final weighting in FrequencyWeighting.values) {
        final filter = WeightingFilter(weighting, 48000);
        final first = [
          for (var i = 0; i < 32; i++) filter.process(i == 0 ? 1 : 0),
        ];
        filter.reset();
        final second = [
          for (var i = 0; i < 32; i++) filter.process(i == 0 ? 1 : 0),
        ];
        expect(second, first);
      }
    });
  });
}
