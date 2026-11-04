import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(Smoothing, () {
    test('defaults to 2 hits within 2 seconds', () {
      const smoothing = Smoothing();
      expect(smoothing.hits, 2);
      expect(smoothing.window, const Duration(seconds: 2));
    });

    test('rejects fewer than 1 hit', () {
      expect(() => Smoothing(hits: 0), throwsA(isA<AssertionError>()));
    });

    test('supports value equality', () {
      expect(const Smoothing(), const Smoothing());
      expect(const Smoothing(), isNot(const Smoothing(hits: 3)));
      expect(const Smoothing(), isNot(const Smoothing(window: Duration.zero)));
    });

    test('has a consistent hashCode', () {
      expect(const Smoothing().hashCode, const Smoothing().hashCode);
    });

    test('has a readable toString', () {
      expect(
        const Smoothing().toString(),
        'Smoothing(hits: 2, window: 0:00:02.000000)',
      );
    });
  });

  group(ClassifierOptions, () {
    test('defaults to auto backend, 0.5 confidence and default smoothing', () {
      const options = ClassifierOptions();
      expect(options.backend, ClassifierBackend.auto);
      expect(options.minConfidence, 0.5);
      expect(options.smoothing, const Smoothing());
    });

    test('rejects a confidence outside 0 to 1', () {
      expect(
        () => ClassifierOptions(minConfidence: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ClassifierOptions(minConfidence: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports value equality', () {
      expect(const ClassifierOptions(), const ClassifierOptions());
      expect(
        const ClassifierOptions(),
        isNot(const ClassifierOptions(backend: ClassifierBackend.yamnet)),
      );
      expect(
        const ClassifierOptions(),
        isNot(const ClassifierOptions(minConfidence: 0.8)),
      );
      expect(
        const ClassifierOptions(),
        isNot(const ClassifierOptions(smoothing: Smoothing(hits: 1))),
      );
    });

    test('has a consistent hashCode', () {
      expect(
        const ClassifierOptions().hashCode,
        const ClassifierOptions().hashCode,
      );
    });

    test('has a readable toString', () {
      expect(
        const ClassifierOptions().toString(),
        'ClassifierOptions(backend: ClassifierBackend.auto, '
        'minConfidence: 0.5, '
        'smoothing: Smoothing(hits: 2, window: 0:00:02.000000))',
      );
    });
  });
}
