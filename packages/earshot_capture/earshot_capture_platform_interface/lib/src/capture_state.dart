/// The state of the microphone capture session.
enum CaptureState {
  /// Capture is not running.
  idle,

  /// Capture is running and delivering PCM.
  capturing,

  /// The system interrupted capture, for example during a phone call.
  ///
  /// Capture resumes on its own when the interruption ends.
  interrupted,
}
