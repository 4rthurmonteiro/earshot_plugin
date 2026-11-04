import 'package:earshot_classifier_platform_interface/src/classifier_backend.dart';
import 'package:earshot_classifier_platform_interface/src/sound_detection.dart';
import 'package:earshot_classifier_platform_interface/src/sound_group.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/apple_labels.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/earshot_sound.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/yamnet_labels.dart';

final Map<String, EarshotSound> _appleSounds = {
  for (final sound in EarshotSound.values)
    for (final label in sound.appleLabels) label: sound,
};

final Map<String, EarshotSound> _yamnetSounds = {
  for (final sound in EarshotSound.values)
    for (final label in sound.yamnetLabels) label: sound,
};

/// {@template sound_vocabulary}
/// Maps the raw labels of each backend to an [EarshotSound] and a
/// [SoundGroup].
///
/// Backends use it to turn a raw label into a [SoundDetection]:
///
/// - A label listed by an [EarshotSound] maps to that sound and its group.
/// - Any other known label falls back to its group, with no sound.
/// - A label the vocabulary does not know, for example from a newer
///   classifier version, falls back to [SoundGroup.other].
/// - A few labels, such as silence, are never reported.
///
/// Every method throws an [ArgumentError] for [ClassifierBackend.auto], which
/// is not a backend that produces labels.
/// {@endtemplate}
class SoundVocabulary {
  /// {@macro sound_vocabulary}
  const new();

  /// The labels of [backend]: for [ClassifierBackend.yamnet], the 521 labels
  /// in the order of the model's output scores; for
  /// [ClassifierBackend.apple], the labels of SoundAnalysis (version 1) in
  /// alphabetical order.
  List<String> labels(ClassifierBackend backend) =>
      List.unmodifiable(_groups(backend).keys);

  /// The sound that [rawLabel] of [backend] maps to, or `null` if it maps to
  /// none.
  EarshotSound? soundOf(ClassifierBackend backend, String rawLabel) =>
      switch (backend) {
        ClassifierBackend.apple => _appleSounds[rawLabel],
        ClassifierBackend.yamnet => _yamnetSounds[rawLabel],
        ClassifierBackend.auto => throw _autoError(backend),
      };

  /// The group of [rawLabel] of [backend], or `null` if the label is never
  /// reported.
  ///
  /// Labels the vocabulary does not know belong to [SoundGroup.other].
  SoundGroup? groupOf(ClassifierBackend backend, String rawLabel) {
    final groups = _groups(backend);
    if (!groups.containsKey(rawLabel)) return SoundGroup.other;
    return groups[rawLabel];
  }

  /// Builds the detection of [rawLabel], reported by [backend] with
  /// [confidence] at [timestamp], or returns `null` if the label is never
  /// reported.
  SoundDetection? detection({
    required ClassifierBackend backend,
    required String rawLabel,
    required double confidence,
    required Duration timestamp,
  }) {
    final group = groupOf(backend, rawLabel);
    if (group == null) return null;
    return SoundDetection(
      group: group,
      sound: soundOf(backend, rawLabel),
      rawLabel: rawLabel,
      confidence: confidence,
      backend: backend,
      timestamp: timestamp,
    );
  }

  Map<String, SoundGroup?> _groups(ClassifierBackend backend) =>
      switch (backend) {
        ClassifierBackend.apple => appleLabelGroups,
        ClassifierBackend.yamnet => yamnetLabelGroups,
        ClassifierBackend.auto => throw _autoError(backend),
      };

  ArgumentError _autoError(ClassifierBackend backend) =>
      ArgumentError.value(backend, 'backend', 'auto does not produce labels');
}
