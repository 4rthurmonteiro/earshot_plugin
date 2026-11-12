/// The state of the microphone capture session.
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
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
