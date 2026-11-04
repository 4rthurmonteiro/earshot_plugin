import 'package:meta/meta.dart';

/// {@template calibration}
/// A calibration that corrects the readings of a specific device.
///
/// Phone microphones are not measurement microphones. Without calibration,
/// readings are estimates.
/// {@endtemplate}
@immutable
class Calibration {
  /// {@macro calibration}
  const new({this.offsetDb = 0});

  /// The offset, in decibels, added to every reading. Defaults to 0.
  final double offsetDb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Calibration && other.offsetDb == offsetDb;

  @override
  int get hashCode => offsetDb.hashCode;

  @override
  String toString() => 'Calibration(offsetDb: $offsetDb)';
}
