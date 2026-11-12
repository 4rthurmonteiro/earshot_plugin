import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Built at runtime so that equal values are not canonicalized consts.
  final hits = int.parse('3');

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

    test('treats separately built equal values as equal', () {
      final a = Smoothing(hits: hits);
      final b = Smoothing(hits: hits);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const Smoothing()));
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const Smoothing().toString(),
        'Smoothing(hits: 2, window: 0:00:02.000000)',
      );
    });
  });

  group(ClassifierOptions, () {
    test('defaults to no backend, 0.5 confidence and default smoothing', () {
      const options = ClassifierOptions();
      expect(options.backend, isNull);
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

    test('treats separately built equal values as equal', () {
      final a = ClassifierOptions(smoothing: Smoothing(hits: hits));
      final b = ClassifierOptions(smoothing: Smoothing(hits: hits));
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ClassifierOptions()));
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const ClassifierOptions().toString(),
        'ClassifierOptions(backend: null, '
        'minConfidence: 0.5, '
        'smoothing: Smoothing(hits: 2, window: 0:00:02.000000))',
      );
    });
  });
}
