import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_classifier/src/detection_smoother.dart';
import 'package:flutter_test/flutter_test.dart';

SoundDetection _detection(
  int milliseconds, {
  EarshotSound? sound = EarshotSound.dogBark,
  String rawLabel = 'Bark',
}) => SoundDetection(
  group: SoundGroup.animals,
  sound: sound,
  rawLabel: rawLabel,
  confidence: 0.9,
  backend: ClassifierBackend.yamnet,
  timestamp: Duration(milliseconds: milliseconds),
);

void main() {
  group(DetectionSmoother, () {
    test('confirms a sound after 2 hits within 2 seconds by default', () {
      final smoother = DetectionSmoother(const Smoothing());
      expect(smoother.smoothing, const Smoothing());
      expect(smoother.add(_detection(0)), isNull);
      expect(smoother.add(_detection(500)), _detection(500));
      expect(smoother.add(_detection(1000)), _detection(1000));
    });

    test('forgets hits older than the window', () {
      final smoother = DetectionSmoother(const Smoothing());
      expect(smoother.add(_detection(0)), isNull);
      expect(smoother.add(_detection(2001)), isNull);
      expect(smoother.add(_detection(4001)), _detection(4001));
    });

    test('counts a hit exactly at the window edge', () {
      final smoother = DetectionSmoother(const Smoothing());
      expect(smoother.add(_detection(0)), isNull);
      expect(smoother.add(_detection(2000)), _detection(2000));
    });

    test('counts one hit per window for the same sound', () {
      final smoother = DetectionSmoother(const Smoothing(hits: 1));
      expect(smoother.add(_detection(0)), _detection(0));
      expect(
        smoother.add(_detection(0, rawLabel: 'Bow-wow')),
        isNull,
        reason: 'a second label of the same sound in the same window',
      );
    });

    test('keeps sounds apart, and unmapped labels by raw label', () {
      final smoother = DetectionSmoother(const Smoothing());
      expect(smoother.add(_detection(0)), isNull);
      expect(
        smoother.add(_detection(500, sound: EarshotSound.dog, rawLabel: 'Dog')),
        isNull,
      );
      expect(
        smoother.add(_detection(500, sound: null, rawLabel: 'Animal')),
        isNull,
      );
      final animal = _detection(1000, sound: null, rawLabel: 'Animal');
      expect(smoother.add(animal), animal);
    });

    test('passes every detection through with 1 hit', () {
      final smoother = DetectionSmoother(const Smoothing(hits: 1));
      expect(smoother.add(_detection(0)), _detection(0));
    });
  });
}
