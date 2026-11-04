import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  group(SoundDetection, () {
    SoundDetection detection({
      SoundGroup group = SoundGroup.animals,
      EarshotSound? sound = EarshotSound.dog,
      String rawLabel = 'Dog',
      double confidence = 0.9,
      ClassifierBackend backend = ClassifierBackend.yamnet,
      Duration timestamp = const Duration(seconds: 2),
    }) => SoundDetection(
      group: group,
      sound: sound,
      rawLabel: rawLabel,
      confidence: confidence,
      backend: backend,
      timestamp: timestamp,
    );

    test('supports value equality', () {
      expect(detection(), detection());
      expect(detection(), isNot(detection(group: SoundGroup.other)));
      expect(detection(), isNot(detection(sound: EarshotSound.dogBark)));
      expect(detection(), isNot(detection(sound: null)));
      expect(detection(), isNot(detection(rawLabel: 'Bark')));
      expect(detection(), isNot(detection(confidence: 0.5)));
      expect(detection(), isNot(detection(backend: ClassifierBackend.apple)));
      expect(detection(), isNot(detection(timestamp: Duration.zero)));
    });

    test('has a consistent hashCode', () {
      expect(detection().hashCode, detection().hashCode);
    });

    test('has a readable toString', () {
      expect(
        detection().toString(),
        'SoundDetection(group: SoundGroup.animals, sound: EarshotSound.dog, '
        'rawLabel: Dog, '
        'confidence: 0.9, backend: ClassifierBackend.yamnet, '
        'timestamp: 0:00:02.000000)',
      );
    });
  });

  group(ClassifierConfig, () {
    // Built at runtime so that equal values are not canonicalized consts.
    final confidence = double.parse('0.7');

    test('defaults to a 0.5 minimum confidence', () {
      expect(const ClassifierConfig().minConfidence, 0.5);
    });

    test('rejects a confidence outside 0 to 1', () {
      expect(
        () => ClassifierConfig(minConfidence: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ClassifierConfig(minConfidence: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports value equality', () {
      final a = ClassifierConfig(minConfidence: confidence);
      final b = ClassifierConfig(minConfidence: confidence);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ClassifierConfig()));
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const ClassifierConfig().toString(),
        'ClassifierConfig(minConfidence: 0.5)',
      );
    });
  });
}
