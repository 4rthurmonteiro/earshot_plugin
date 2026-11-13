/// The time weighting of the level meter, as defined by IEC 61672-1.
///
/// The meter squares the frequency-weighted signal and averages it
/// exponentially: the reading rises with [timeConstant] and decays with
/// [decayTimeConstant].
enum TimeWeighting {
  /// Fast, with a 125 ms time constant.
  fast(Duration(milliseconds: 125), Duration(milliseconds: 125)),

  /// Slow, with a 1 s time constant.
  slow(Duration(seconds: 1), Duration(seconds: 1)),

  /// Impulse, with a 35 ms time constant on the rise and a 1.5 s
  /// time constant on the decay.
  impulse(Duration(milliseconds: 35), Duration(milliseconds: 1500));

  new(this.timeConstant, this.decayTimeConstant);

  /// The exponential time constant while the level rises.
  ///
  /// For [fast] and [slow] it equals [decayTimeConstant].
  final Duration timeConstant;

  /// The exponential time constant while the level decays.
  final Duration decayTimeConstant;
}
