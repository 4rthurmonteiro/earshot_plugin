/// The frequency weighting applied before the level is measured, as defined
/// by IEC 61672-1.
enum Weighting {
  /// A-weighting, which follows the sensitivity of human hearing at
  /// moderate levels. Readings are in dB(A).
  a,

  /// C-weighting, which is nearly flat and suits loud and low-frequency
  /// sounds. Readings are in dB(C).
  c,

  /// Z-weighting, which is flat (no weighting). Readings are in dB(Z).
  z,
}
