import 'dart:math' as math;
import 'dart:typed_data';

/// {@template linear_phase_fir}
/// A symmetric (linear-phase) FIR filter whose amplitude response is fitted
/// to a target magnitude by weighted least squares.
///
/// Internal to `earshot_level`. It models the part of an analog response
/// that the bilinear transform cannot reproduce near the Nyquist frequency.
/// {@endtemplate}
class LinearPhaseFir {
  /// {@macro linear_phase_fir}
  ///
  /// Fits `2 * halfOrder + 1` taps so that the amplitude response follows
  /// [target], a positive magnitude as a function of the normalized angular
  /// frequency in radians per sample, from 0 to π. The error is weighted by
  /// `1 / target²`, so the fit minimizes the relative (decibel) error.
  new fit({required double Function(double omega) target, int halfOrder = 6})
    : taps = _fit(target, halfOrder),
      _delay = Float64List(2 * halfOrder + 1);

  static const _gridSize = 512;

  /// The filter taps, symmetric around the middle one.
  final Float64List taps;

  final Float64List _delay;
  int _head = 0;

  /// Filters one sample.
  double process(double x) {
    final n = taps.length;
    _head = _head == 0 ? n - 1 : _head - 1;
    _delay[_head] = x;
    var y = 0.0;
    var index = _head;
    for (var i = 0; i < n; i++) {
      y += taps[i] * _delay[index];
      index = index == n - 1 ? 0 : index + 1;
    }
    return y;
  }

  /// Clears the filter state, as if it had only seen silence.
  void reset() {
    _delay.fillRange(0, _delay.length, 0);
    _head = 0;
  }

  /// The magnitude of the frequency response at the normalized angular
  /// frequency [omega], in radians per sample.
  double magnitudeAt(double omega) {
    final m = taps.length ~/ 2;
    var amplitude = taps[m];
    for (var k = 1; k <= m; k++) {
      amplitude += 2 * taps[m + k] * math.cos(k * omega);
    }
    return amplitude.abs();
  }

  static Float64List _fit(double Function(double) target, int halfOrder) {
    // Amplitude: A(ω) = c0 + Σ 2 ck cos(kω), linear in c. Solve the weighted
    // normal equations G c = r on a uniform grid over [0, π].
    final size = halfOrder + 1;
    final g = List.generate(size, (_) => Float64List(size));
    final r = Float64List(size);
    final basis = Float64List(size);
    for (var i = 0; i <= _gridSize; i++) {
      final omega = math.pi * i / _gridSize;
      final t = target(omega);
      final weight = 1 / (t * t);
      basis[0] = 1;
      for (var k = 1; k < size; k++) {
        basis[k] = 2 * math.cos(k * omega);
      }
      for (var j = 0; j < size; j++) {
        r[j] += weight * basis[j] * t;
        for (var k = 0; k < size; k++) {
          g[j][k] += weight * basis[j] * basis[k];
        }
      }
    }
    final c = _solve(g, r);
    final taps = Float64List(2 * halfOrder + 1);
    taps[halfOrder] = c[0];
    for (var k = 1; k <= halfOrder; k++) {
      taps[halfOrder + k] = c[k];
      taps[halfOrder - k] = c[k];
    }
    return taps;
  }

  /// Solves the symmetric positive definite system [a] x = [b] by Cholesky
  /// decomposition. Overwrites [a].
  static Float64List _solve(List<Float64List> a, Float64List b) {
    final n = b.length;
    for (var j = 0; j < n; j++) {
      var d = a[j][j];
      for (var k = 0; k < j; k++) {
        d -= a[j][k] * a[j][k];
      }
      a[j][j] = math.sqrt(d);
      for (var i = j + 1; i < n; i++) {
        var s = a[i][j];
        for (var k = 0; k < j; k++) {
          s -= a[i][k] * a[j][k];
        }
        a[i][j] = s / a[j][j];
      }
    }
    final y = Float64List(n);
    for (var i = 0; i < n; i++) {
      var s = b[i];
      for (var k = 0; k < i; k++) {
        s -= a[i][k] * y[k];
      }
      y[i] = s / a[i][i];
    }
    final x = Float64List(n);
    for (var i = n - 1; i >= 0; i--) {
      var s = y[i];
      for (var k = i + 1; k < n; k++) {
        s -= a[k][i] * x[k];
      }
      x[i] = s / a[i][i];
    }
    return x;
  }
}
