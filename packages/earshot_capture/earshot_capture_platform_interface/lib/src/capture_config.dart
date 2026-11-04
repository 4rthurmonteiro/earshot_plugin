import 'package:earshot_capture_platform_interface/src/sample_rate.dart';
import 'package:meta/meta.dart';

/// {@template capture_config}
/// The configuration of a microphone capture session.
/// {@endtemplate}
@immutable
class CaptureConfig {
  /// {@macro capture_config}
  const new({this.sampleRate = SampleRate.hz16000});

  /// The rate PCM is delivered at. Defaults to [SampleRate.hz16000].
  final SampleRate sampleRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptureConfig && other.sampleRate == sampleRate;

  @override
  int get hashCode => sampleRate.hashCode;

  @override
  String toString() => 'CaptureConfig(sampleRate: $sampleRate)';
}
