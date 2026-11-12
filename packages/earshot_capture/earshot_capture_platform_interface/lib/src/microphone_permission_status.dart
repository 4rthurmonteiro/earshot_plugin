/// The status of the microphone permission for this app.
///
/// Reading the status never prompts the user.
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
enum MicrophonePermissionStatus {
  /// The user allowed microphone access.
  granted,

  /// The user denied microphone access.
  ///
  /// On Android this is also returned when the app has never asked, because
  /// Android cannot tell the two apart without an `Activity`.
  denied,

  /// The app has not asked for microphone access yet.
  ///
  /// Never returned on Android. See [denied].
  undetermined,

  /// Microphone access is blocked by a policy the user cannot change, such as
  /// parental controls or device management.
  restricted,
}
