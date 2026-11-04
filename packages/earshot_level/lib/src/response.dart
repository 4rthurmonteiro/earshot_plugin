/// The time weighting of the level meter, as defined by IEC 61672-1.
enum Response {
  /// Fast response, with a 125 ms time constant.
  fast(Duration(milliseconds: 125)),

  /// Slow response, with a 1 s time constant.
  slow(Duration(seconds: 1)),

  /// Impulse response, with a 35 ms time constant on the rise.
  impulse(Duration(milliseconds: 35));

  new(this.timeConstant);

  /// The exponential time constant of this response.
  final Duration timeConstant;
}
