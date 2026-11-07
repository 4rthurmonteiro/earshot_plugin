import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:test/test.dart';

class _MockEarshotClassifierPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotClassifierPlatform;

class _ImplementsOnlyEarshotClassifierPlatform extends Mock
    implements EarshotClassifierPlatform;

class _ExtendingEarshotClassifierPlatform extends EarshotClassifierPlatform;

final TypeMatcher<UnimplementedError> _notImplemented =
    isA<UnimplementedError>().having(
      (error) => error.message,
      'message',
      kClassifierNotImplementedMessage,
    );

void main() {
  group(EarshotClassifierPlatform, () {
    late EarshotClassifierPlatform initialInstance;

    setUpAll(() => initialInstance = EarshotClassifierPlatform.instance);
    tearDown(() => EarshotClassifierPlatform.instance = initialInstance);

    test('defaults to $UnsupportedEarshotClassifier', () {
      expect(initialInstance, isA<UnsupportedEarshotClassifier>());
    });

    test('accepts a mock with $MockPlatformInterfaceMixin', () {
      final platform = _MockEarshotClassifierPlatform();
      EarshotClassifierPlatform.instance = platform;
      expect(EarshotClassifierPlatform.instance, same(platform));
    });

    test('accepts an implementation that extends it', () {
      final platform = _ExtendingEarshotClassifierPlatform();
      EarshotClassifierPlatform.instance = platform;
      expect(EarshotClassifierPlatform.instance, same(platform));
    });

    test('rejects an implementation that only implements it', () {
      expect(
        () => EarshotClassifierPlatform.instance =
            _ImplementsOnlyEarshotClassifierPlatform(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isAvailable completes with an error by default', () {
      expect(
        _ExtendingEarshotClassifierPlatform().isAvailable(),
        throwsA(_notImplemented),
      );
    });

    test('detections returns a stream that errors by default', () {
      expect(
        _ExtendingEarshotClassifierPlatform().detections(
          const ClassifierConfig(),
        ),
        emitsError(_notImplemented),
      );
    });

    test('classify returns a stream that errors by default', () {
      expect(
        _ExtendingEarshotClassifierPlatform().classify(
          const Stream<PcmChunk>.empty(),
          const ClassifierConfig(),
        ),
        emitsError(_notImplemented),
      );
    });
  });

  group(UnsupportedEarshotClassifier, () {
    test('detections returns a stream that errors', () {
      expect(
        UnsupportedEarshotClassifier().detections(const ClassifierConfig()),
        emitsError(_notImplemented),
      );
    });

    test('classify returns a stream that errors', () {
      expect(
        UnsupportedEarshotClassifier().classify(
          const Stream<PcmChunk>.empty(),
          const ClassifierConfig(),
        ),
        emitsError(_notImplemented),
      );
    });
  });
}
