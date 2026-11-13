import 'package:meta/meta.dart';

/// {@template level_calibration}
/// A calibration that corrects the readings of a specific device.
///
/// Phone microphones are not measurement microphones. Without calibration,
/// readings are estimates.
/// {@endtemplate}
@immutable
class LevelCalibration {
  /// {@macro level_calibration}
  const new({this.offsetDb = 0});

  /// The offset, in decibels, added to every reading. Defaults to 0.
  final double offsetDb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelCalibration && other.offsetDb == offsetDb;

  @override
  int get hashCode => offsetDb.hashCode;

  @override
  String toString() => 'LevelCalibration(offsetDb: $offsetDb)';
}
