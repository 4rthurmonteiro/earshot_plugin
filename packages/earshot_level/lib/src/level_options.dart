import 'package:earshot_level/src/frequency_weighting.dart';
import 'package:earshot_level/src/level_calibration.dart';
import 'package:earshot_level/src/time_weighting.dart';
import 'package:meta/meta.dart';

/// {@template level_options}
/// How the level meter measures sound.
/// {@endtemplate}
@immutable
class LevelOptions {
  /// {@macro level_options}
  const new({
    this.weighting = FrequencyWeighting.a,
    this.timeWeighting = TimeWeighting.fast,
    this.calibration = const LevelCalibration(),
  });

  /// The frequency weighting. Defaults to [FrequencyWeighting.a].
  final FrequencyWeighting weighting;

  /// The time weighting. Defaults to [TimeWeighting.fast].
  final TimeWeighting timeWeighting;

  /// The device calibration. Defaults to no offset.
  final LevelCalibration calibration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelOptions &&
          other.weighting == weighting &&
          other.timeWeighting == timeWeighting &&
          other.calibration == calibration;

  @override
  int get hashCode => Object.hash(weighting, timeWeighting, calibration);

  @override
  String toString() =>
      'LevelOptions(weighting: $weighting, timeWeighting: $timeWeighting, '
      'calibration: $calibration)';
}
