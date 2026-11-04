/// The engine that classifies sounds.
///
/// Confidence scores from different backends cannot be compared. Pick
/// [yamnet] on every platform for consistent results.
enum ClassifierBackend {
  /// [apple] on iOS and macOS, [yamnet] everywhere else.
  auto,

  /// Apple's SoundAnalysis framework. iOS and macOS only.
  apple,

  /// Google's YAMNet model, run on-device with LiteRT. Every platform.
  yamnet,
}
