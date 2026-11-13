import 'package:earshot_level/src/frequency_weighting.dart';
import 'package:meta/meta.dart';

/// {@template level_reading}
/// A sound level measurement.
///
/// Every level is in decibels. Without calibration, 0 dB is the level of a
/// full-scale sine (an RMS of 1/√2), so a full-scale 1 kHz sine reads 0 dB
/// with every weighting. The calibration offset is added to every level.
///
/// Digital silence reads [floorDb] plus the calibration offset, never
/// negative infinity.
/// {@endtemplate}
@immutable
class LevelReading {
  /// {@macro level_reading}
  const new({
    required this.db,
    required this.leq,
    required this.leq1s,
    required this.leq60s,
    required this.weighting,
    required this.timestamp,
  });

  /// The lowest level a reading reports before calibration, in decibels.
  static const floorDb = -200.0;

  /// The time-weighted sound level, in decibels.
  final double db;

  /// The equivalent continuous sound level (Leq) since the session started,
  /// in decibels.
  final double leq;

  /// The equivalent continuous sound level (Leq) over the last second, in
  /// decibels.
  ///
  /// During the first second it covers the audio heard so far.
  final double leq1s;

  /// The equivalent continuous sound level (Leq) over the last 60 seconds,
  /// in decibels.
  ///
  /// During the first 60 seconds it covers the audio heard so far.
  final double leq60s;

  /// The frequency weighting every level was measured with.
  final FrequencyWeighting weighting;

  /// The time just after the last sample measured, relative to the start of
  /// capture.
  final Duration timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelReading &&
          other.db == db &&
          other.leq == leq &&
          other.leq1s == leq1s &&
          other.leq60s == leq60s &&
          other.weighting == weighting &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(db, leq, leq1s, leq60s, weighting, timestamp);

  @override
  String toString() =>
      'LevelReading(db: $db, leq: $leq, leq1s: $leq1s, leq60s: $leq60s, '
      'weighting: $weighting, timestamp: $timestamp)';
}
