import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  group(SoundDetection, () {
    SoundDetection detection({
      SoundGroup group = SoundGroup.animals,
      String rawLabel = 'Dog',
      double confidence = 0.9,
      ClassifierBackend backend = ClassifierBackend.yamnet,
      Duration timestamp = const Duration(seconds: 2),
    }) => SoundDetection(
      group: group,
      rawLabel: rawLabel,
      confidence: confidence,
      backend: backend,
      timestamp: timestamp,
    );

    test('supports value equality', () {
      expect(detection(), detection());
      expect(detection(), isNot(detection(group: SoundGroup.other)));
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
        'SoundDetection(group: SoundGroup.animals, rawLabel: Dog, '
        'confidence: 0.9, backend: ClassifierBackend.yamnet, '
        'timestamp: 0:00:02.000000)',
      );
    });
  });
}
