import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:meta/meta.dart';

/// {@template earshot_event}
/// What earshot heard at one point in time.
/// {@endtemplate}
@immutable
class EarshotEvent {
  /// {@macro earshot_event}
  const new({required this.timestamp, this.level, this.detections = const []});

  /// The time of the event, relative to the start of listening.
  final Duration timestamp;

  /// The sound level, or `null` if level metering is off.
  final LevelReading? level;

  /// The sounds confirmed since the previous event. Often empty.
  final List<SoundDetection> detections;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EarshotEvent ||
        other.timestamp != timestamp ||
        other.level != level ||
        other.detections.length != detections.length) {
      return false;
    }
    for (var i = 0; i < detections.length; i++) {
      if (other.detections[i] != detections[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(timestamp, level, Object.hashAll(detections));

  @override
  String toString() =>
      'EarshotEvent(timestamp: $timestamp, level: $level, '
      'detections: $detections)';
}
