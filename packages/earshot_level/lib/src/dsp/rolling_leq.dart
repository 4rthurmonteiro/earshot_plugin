import 'dart:typed_data';

/// {@template rolling_leq}
/// The mean square of the most recent window of a signal, from 10 ms bins.
///
/// Internal to `earshot_level`. Each completed bin stores its mean square in
/// a ring buffer of [binCount] entries. The window always spans exactly
/// [binCount] bins: when the current bin is partly filled, the matching
/// fraction of the oldest bin is left out, assuming the signal is steady
/// within a bin. Before the window has filled, the mean square covers the
/// audio seen so far.
/// {@endtemplate}
class RollingLeq {
  /// {@macro rolling_leq}
  new(this.binCount) : _bins = Float64List(binCount);

  /// The length of the window, in bins.
  final int binCount;

  final Float64List _bins;
  int _next = 0;
  int _filled = 0;

  /// Adds the mean square of a completed bin.
  void addBin(double meanSquare) {
    _bins[_next] = meanSquare;
    _next = (_next + 1) % binCount;
    if (_filled < binCount) _filled++;
  }

  /// The mean square over the window, given the current partial bin.
  ///
  /// [partialMeanSquare] is the mean square of the samples in the current
  /// bin so far, and [partialFraction] is how much of the bin they fill,
  /// from 0 (empty) to below 1.
  double meanSquare({
    required double partialMeanSquare,
    required double partialFraction,
  }) {
    var sum = 0.0;
    for (var i = 0; i < _filled; i++) {
      sum += _bins[i];
    }
    if (_filled < binCount) {
      return (sum + partialMeanSquare * partialFraction) /
          (_filled + partialFraction);
    }
    // The ring is full, so _next points at the oldest bin.
    final oldest = _bins[_next];
    return (sum + (partialMeanSquare - oldest) * partialFraction) / binCount;
  }
}
