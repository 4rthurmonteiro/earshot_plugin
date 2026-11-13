import 'dart:math' as math;

import 'package:earshot_level/earshot_level.dart';
import 'package:earshot_level/src/dsp/time_weighting_filter.dart';
import 'package:test/test.dart';

import '../../helpers/signals.dart';

const _rate = 48000;

/// Feeds [square] for [seconds] and returns the mean square.
double _feed(TimeWeightingFilter weighting, double square, double seconds) {
  final count = (seconds * _rate).round();
  for (var i = 0; i < count; i++) {
    weighting.add(square);
  }
  return weighting.meanSquare;
}

double _seconds(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerSecond;

void main() {
  group(TimeWeightingFilter, () {
    test('starts from silence', () {
      expect(TimeWeightingFilter(TimeWeighting.fast, _rate).meanSquare, 0);
    });

    test('add returns the updated mean square', () {
      final weighting = TimeWeightingFilter(TimeWeighting.fast, _rate);
      expect(weighting.add(1), weighting.meanSquare);
      expect(weighting.meanSquare, greaterThan(0));
    });

    for (final response in TimeWeighting.values) {
      test('$response rises to 1 - 1/e of a step after its rise time '
          'constant', () {
        final weighting = TimeWeightingFilter(response, _rate);
        final tau = _seconds(response.timeConstant);
        expect(_feed(weighting, 1, tau), closeTo(1 - 1 / math.e, 1e-3));
      });

      test('$response decays at 10·log10(e)/τ dB per second', () {
        final weighting = TimeWeightingFilter(response, _rate)..meanSquare = 1;
        final decayDb = -powerDb(_feed(weighting, 0, 1));
        final tau = _seconds(response.decayTimeConstant);
        expect(decayDb, closeTo(10 / math.ln10 / tau, 0.01));
      });
    }

    test('decays at the IEC 61672-1 rates', () {
      double decayPerSecond(TimeWeighting response) {
        final weighting = TimeWeightingFilter(response, _rate)..meanSquare = 1;
        return -powerDb(_feed(weighting, 0, 1));
      }

      // IEC 61672-1, 5.8: at least 25 dB/s for Fast, 3.4 to 5.3 dB/s for
      // Slow, and 2.9 dB/s ± 0.5 dB/s for Impulse.
      expect(decayPerSecond(TimeWeighting.fast), greaterThanOrEqualTo(25));
      expect(decayPerSecond(TimeWeighting.slow), inInclusiveRange(3.4, 5.3));
      expect(decayPerSecond(TimeWeighting.impulse), closeTo(2.9, 0.5));
    });

    test('impulse rises fast and decays slowly', () {
      final weighting = TimeWeightingFilter(TimeWeighting.impulse, _rate);
      expect(_feed(weighting, 1, 0.035), closeTo(1 - 1 / math.e, 1e-3));
      final peak = weighting.meanSquare;
      expect(_feed(weighting, 0, 0.035), greaterThan(0.97 * peak));
    });
  });
}
