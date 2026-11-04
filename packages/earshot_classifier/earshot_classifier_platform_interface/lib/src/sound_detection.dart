import 'package:earshot_classifier_platform_interface/src/classifier_backend.dart';
import 'package:earshot_classifier_platform_interface/src/sound_group.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/earshot_sound.dart';
import 'package:meta/meta.dart';

/// {@template sound_detection}
/// A sound recognized by the classifier.
///
/// earshot is informational and is not a certified detector.
/// {@endtemplate}
@immutable
class SoundDetection {
  /// {@macro sound_detection}
  ///
  /// When [sound] is set, [group] must be its group.
  const new({
    required this.group,
    required this.rawLabel,
    required this.confidence,
    required this.backend,
    required this.timestamp,
    this.sound,
  });

  /// The group the sound belongs to.
  ///
  /// Always set, even when the label maps to no [sound].
  final SoundGroup group;

  /// The sound that [rawLabel] maps to, or `null` if it maps to no
  /// [EarshotSound]. In that case only [group] and [rawLabel] identify the
  /// sound.
  final EarshotSound? sound;

  /// The label exactly as the [backend] reported it.
  final String rawLabel;

  /// The backend's confidence, from 0 to 1.
  ///
  /// Scores from different backends cannot be compared.
  final double confidence;

  /// The backend that produced this detection: [ClassifierBackend.apple] or
  /// [ClassifierBackend.yamnet], never [ClassifierBackend.auto].
  final ClassifierBackend backend;

  /// The time of the detection, relative to the start of capture.
  final Duration timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundDetection &&
          other.group == group &&
          other.sound == sound &&
          other.rawLabel == rawLabel &&
          other.confidence == confidence &&
          other.backend == backend &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      Object.hash(group, sound, rawLabel, confidence, backend, timestamp);

  @override
  String toString() =>
      'SoundDetection(group: $group, sound: $sound, rawLabel: $rawLabel, '
      'confidence: $confidence, backend: $backend, timestamp: $timestamp)';
}
