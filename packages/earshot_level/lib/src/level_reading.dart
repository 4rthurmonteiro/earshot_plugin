import 'package:earshot_level/src/weighting.dart';
import 'package:meta/meta.dart';

/// {@template level_reading}
/// A sound level measurement.
/// {@endtemplate}
@immutable
class LevelReading {
  /// {@macro level_reading}
  const new({
    required this.db,
    required this.leq,
    required this.weighting,
    required this.timestamp,
  });

  /// The time-weighted sound level, in decibels.
  final double db;

  /// The equivalent continuous sound level (Leq) since the session started,
  /// in decibels.
  final double leq;

  /// The frequency weighting both levels were measured with.
  final Weighting weighting;

  /// The time of the reading, relative to the start of capture.
  final Duration timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelReading &&
          other.db == db &&
          other.leq == leq &&
          other.weighting == weighting &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(db, leq, weighting, timestamp);

  @override
  String toString() =>
      'LevelReading(db: $db, leq: $leq, weighting: $weighting, '
      'timestamp: $timestamp)';
}
