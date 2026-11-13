import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  group(ClassifierException, () {
    test('supports value equality', () {
      const a = ClassifierException(ClassifierErrorCode.unsupported, 'web');
      const b = ClassifierException(ClassifierErrorCode.unsupported, 'web');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const ClassifierException(ClassifierErrorCode.unsupported)),
      );
      expect(
        a,
        isNot(
          const ClassifierException(
            ClassifierErrorCode.modelUnavailable,
            'web',
          ),
        ),
      );
      expect(a, isNot(Object()));
    });

    test('has a readable toString', () {
      expect(
        const ClassifierException(ClassifierErrorCode.modelUnavailable)
            .toString(),
        'ClassifierException(modelUnavailable)',
      );
      expect(
        const ClassifierException(
          ClassifierErrorCode.unknown,
          'boom',
        ).toString(),
        'ClassifierException(unknown, boom)',
      );
    });
  });
}
