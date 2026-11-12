/// The engine that classifies sounds.
///
/// Confidence scores from different backends cannot be compared. Pick
/// [yamnet] on every platform for consistent results. To let earshot pick
/// the best backend for the platform, leave the backend `null` in the
/// classifier options.
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
enum ClassifierBackend {
  /// Apple's SoundAnalysis framework. iOS and macOS only.
  apple,

  /// Google's YAMNet model, run on-device with LiteRT. Every platform.
  yamnet,
}
