import 'package:earshot_level/src/calibration.dart';
import 'package:earshot_level/src/response.dart';
import 'package:earshot_level/src/weighting.dart';
import 'package:meta/meta.dart';

/// {@template level_options}
/// How the level meter measures sound.
/// {@endtemplate}
@immutable
class LevelOptions {
  /// {@macro level_options}
  const new({
    this.weighting = Weighting.a,
    this.response = Response.fast,
    this.calibration = const Calibration(),
  });

  /// The frequency weighting. Defaults to [Weighting.a].
  final Weighting weighting;

  /// The time weighting. Defaults to [Response.fast].
  final Response response;

  /// The device calibration. Defaults to no offset.
  final Calibration calibration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelOptions &&
          other.weighting == weighting &&
          other.response == response &&
          other.calibration == calibration;

  @override
  int get hashCode => Object.hash(weighting, response, calibration);

  @override
  String toString() =>
      'LevelOptions(weighting: $weighting, response: $response, '
      'calibration: $calibration)';
}
