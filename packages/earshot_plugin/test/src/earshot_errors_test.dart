import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:earshot_plugin/src/earshot_errors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toEarshotException', () {
    EarshotException map(Object error, {bool fromClassifier = false}) =>
        toEarshotException(error, fromClassifier: fromClassifier);

    test('returns an EarshotException as is', () {
      const error = EarshotException(EarshotErrorCode.unsupported, 'web');
      expect(identical(map(error), error), isTrue);
    });

    test('keeps the code and message of a CaptureException', () {
      const expected = {
        CaptureErrorCode.permissionDenied: EarshotErrorCode.permissionDenied,
        CaptureErrorCode.audioUnavailable: EarshotErrorCode.audioUnavailable,
        CaptureErrorCode.sampleRateConflict:
            EarshotErrorCode.sampleRateConflict,
        CaptureErrorCode.unknown: EarshotErrorCode.unknown,
      };
      expect(expected.keys, containsAll(CaptureErrorCode.values));
      for (final MapEntry(:key, :value) in expected.entries) {
        final error = CaptureException(key, 'details');
        for (final fromClassifier in [false, true]) {
          expect(
            map(error, fromClassifier: fromClassifier),
            EarshotException(value, 'details', error),
          );
        }
      }
    });

    test('keeps the code and message of a ClassifierException', () {
      const expected = {
        ClassifierErrorCode.unsupported: EarshotErrorCode.unsupported,
        ClassifierErrorCode.modelUnavailable: EarshotErrorCode.modelUnavailable,
        ClassifierErrorCode.unknown: EarshotErrorCode.unknown,
      };
      expect(expected.keys, containsAll(ClassifierErrorCode.values));
      for (final MapEntry(:key, :value) in expected.entries) {
        final error = ClassifierException(key, 'details');
        for (final fromClassifier in [false, true]) {
          expect(
            map(error, fromClassifier: fromClassifier),
            EarshotException(value, 'details', error),
          );
        }
      }
    });

    test('maps a PlatformException whose code names an error code', () {
      final error = PlatformException(code: 'permissionDenied', message: 'no');
      expect(
        map(error, fromClassifier: true),
        EarshotException(EarshotErrorCode.permissionDenied, 'no', error),
      );
    });

    test('treats any other PlatformException as any other error', () {
      final error = PlatformException(code: 'boom');
      expect(
        map(error),
        EarshotException(EarshotErrorCode.unknown, '$error', error),
      );
      expect(
        map(error, fromClassifier: true),
        EarshotException(EarshotErrorCode.modelUnavailable, '$error', error),
      );
    });

    test('maps UnsupportedError and UnimplementedError to unsupported', () {
      final unsupported = UnsupportedError('android');
      final unimplemented = UnimplementedError('stub');
      expect(
        map(unsupported, fromClassifier: true),
        EarshotException(EarshotErrorCode.unsupported, 'android', unsupported),
      );
      expect(
        map(unimplemented),
        EarshotException(EarshotErrorCode.unsupported, 'stub', unimplemented),
      );
    });

    test('maps other classifier errors to modelUnavailable', () {
      final error = StateError('no model');
      expect(
        map(error, fromClassifier: true),
        EarshotException(EarshotErrorCode.modelUnavailable, '$error', error),
      );
    });

    test('maps other errors to unknown', () {
      final error = StateError('boom');
      expect(
        map(error),
        EarshotException(EarshotErrorCode.unknown, '$error', error),
      );
    });
  });
}
