import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockEarshotClassifierPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotClassifierPlatform;

void main() {
  group(EarshotClassifier, () {
    late EarshotClassifierPlatform platform;

    setUp(() {
      platform = _MockEarshotClassifierPlatform();
      EarshotClassifierPlatform.instance = platform;
    });

    test('defaults to the default options', () {
      expect(const EarshotClassifier().options, const ClassifierOptions());
    });

    test('detections delegates to the platform', () {
      const detection = SoundDetection(
        group: SoundGroup.animals,
        rawLabel: 'Dog',
        confidence: 0.9,
        backend: ClassifierBackend.yamnet,
        timestamp: Duration.zero,
      );
      when(platform.detections).thenAnswer((_) => Stream.value(detection));

      expect(const EarshotClassifier().detections(), emits(detection));
      verify(platform.detections).called(1);
    });
  });
}
