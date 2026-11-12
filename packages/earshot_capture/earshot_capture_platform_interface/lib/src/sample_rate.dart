/// The sample rates that capture can deliver PCM at.
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
enum SampleRate {
  /// 16 kHz, the rate sound classifiers such as YAMNet expect.
  hz16000(16000),

  /// 44.1 kHz.
  hz44100(44100),

  /// 48 kHz, the native rate of most phone microphones.
  hz48000(48000);

  new(this.hz);

  /// The rate in samples per second.
  final int hz;
}
