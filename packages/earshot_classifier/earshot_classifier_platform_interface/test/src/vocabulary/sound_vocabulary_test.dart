import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  const vocabulary = SoundVocabulary();

  group(SoundVocabulary, () {
    test('lists YAMNet labels in model output order', () {
      final labels = vocabulary.labels(ClassifierBackend.yamnet);
      expect(labels, hasLength(521));
      expect(labels[0], 'Speech');
      expect(labels[70], 'Bark');
      expect(labels[393], 'Smoke detector, smoke alarm');
      expect(labels[520], 'Field recording');
    });

    test('lists the Apple labels', () {
      final labels = vocabulary.labels(ClassifierBackend.apple);
      expect(labels, hasLength(303));
      expect(labels, containsAll(['dog_bark', 'smoke_detector', 'speech']));
    });

    test('maps a label to its sound', () {
      expect(
        vocabulary.soundOf(ClassifierBackend.yamnet, 'Bark'),
        EarshotSound.dogBark,
      );
      expect(
        vocabulary.soundOf(ClassifierBackend.apple, 'dog_bow_wow'),
        EarshotSound.dogBark,
      );
      expect(
        vocabulary.soundOf(ClassifierBackend.apple, 'smoke_detector'),
        EarshotSound.smokeAlarm,
      );
      expect(vocabulary.soundOf(ClassifierBackend.yamnet, 'Animal'), isNull);
    });

    test('maps a label to its group, falling back for unmapped labels', () {
      expect(
        vocabulary.groupOf(ClassifierBackend.yamnet, 'Bark'),
        SoundGroup.animals,
      );
      expect(
        vocabulary.groupOf(ClassifierBackend.yamnet, 'Animal'),
        SoundGroup.animals,
      );
      expect(
        vocabulary.groupOf(ClassifierBackend.apple, 'didgeridoo'),
        SoundGroup.music,
      );
    });

    test('puts unknown labels in the other group', () {
      expect(
        vocabulary.groupOf(ClassifierBackend.apple, 'not_a_label'),
        SoundGroup.other,
      );
    });

    test('never reports silence', () {
      expect(vocabulary.groupOf(ClassifierBackend.yamnet, 'Silence'), isNull);
      expect(vocabulary.groupOf(ClassifierBackend.apple, 'silence'), isNull);
    });

    test('builds a detection with the mapped sound', () {
      expect(
        vocabulary.detection(
          backend: ClassifierBackend.yamnet,
          rawLabel: 'Bark',
          confidence: 0.8,
          timestamp: const Duration(seconds: 1),
        ),
        const SoundDetection(
          group: SoundGroup.animals,
          sound: EarshotSound.dogBark,
          rawLabel: 'Bark',
          confidence: 0.8,
          backend: ClassifierBackend.yamnet,
          timestamp: Duration(seconds: 1),
        ),
      );
    });

    test('builds a detection with only the group for unmapped labels', () {
      expect(
        vocabulary.detection(
          backend: ClassifierBackend.apple,
          rawLabel: 'didgeridoo',
          confidence: 0.7,
          timestamp: Duration.zero,
        ),
        const SoundDetection(
          group: SoundGroup.music,
          rawLabel: 'didgeridoo',
          confidence: 0.7,
          backend: ClassifierBackend.apple,
          timestamp: Duration.zero,
        ),
      );
    });

    test('builds no detection for silence', () {
      expect(
        vocabulary.detection(
          backend: ClassifierBackend.yamnet,
          rawLabel: 'Silence',
          confidence: 0.9,
          timestamp: Duration.zero,
        ),
        isNull,
      );
    });

    test('rejects the auto backend', () {
      expect(
        () => vocabulary.labels(ClassifierBackend.auto),
        throwsArgumentError,
      );
      expect(
        () => vocabulary.soundOf(ClassifierBackend.auto, 'Bark'),
        throwsArgumentError,
      );
    });
  });

  group(EarshotSound, () {
    test('lists its labels per backend', () {
      expect(EarshotSound.dogBark.labelsOf(ClassifierBackend.apple), [
        'dog_bark',
        'dog_bow_wow',
      ]);
      expect(
        EarshotSound.dogBark.labelsOf(ClassifierBackend.yamnet),
        contains('Bark'),
      );
    });

    test('tells which backends support it', () {
      expect(
        EarshotSound.smokeAlarm.isSupportedBy(ClassifierBackend.apple),
        isTrue,
      );
      expect(
        EarshotSound.carAlarm.isSupportedBy(ClassifierBackend.apple),
        isFalse,
      );
      expect(
        EarshotSound.noseBlowing.isSupportedBy(ClassifierBackend.yamnet),
        isFalse,
      );
    });

    test('rejects the auto backend', () {
      expect(
        () => EarshotSound.dog.isSupportedBy(ClassifierBackend.auto),
        throwsArgumentError,
      );
    });

    test('has a display name and a group', () {
      expect(EarshotSound.smokeAlarm.displayName, 'Smoke alarm');
      expect(EarshotSound.smokeAlarm.group, SoundGroup.alarms);
    });

    test('covers every group', () {
      expect({
        for (final sound in EarshotSound.values) sound.group,
      }, SoundGroup.values.toSet());
    });
  });
}
