import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:test/test.dart';

class _MockEarshotCapturePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotCapturePlatform;

class _ImplementsOnlyEarshotCapturePlatform extends Mock
    implements EarshotCapturePlatform;

class _ExtendingEarshotCapturePlatform extends EarshotCapturePlatform;

final TypeMatcher<UnimplementedError> _notImplemented =
    isA<UnimplementedError>().having(
      (error) => error.message,
      'message',
      kCaptureNotImplementedMessage,
    );

void main() {
  group(EarshotCapturePlatform, () {
    late EarshotCapturePlatform initialInstance;

    setUpAll(() => initialInstance = EarshotCapturePlatform.instance);
    tearDown(() => EarshotCapturePlatform.instance = initialInstance);

    test('defaults to $UnsupportedEarshotCapture', () {
      expect(initialInstance, isA<UnsupportedEarshotCapture>());
    });

    test('accepts a mock with $MockPlatformInterfaceMixin', () {
      final platform = _MockEarshotCapturePlatform();
      EarshotCapturePlatform.instance = platform;
      expect(EarshotCapturePlatform.instance, same(platform));
    });

    test('accepts an implementation that extends it', () {
      final platform = _ExtendingEarshotCapturePlatform();
      EarshotCapturePlatform.instance = platform;
      expect(EarshotCapturePlatform.instance, same(platform));
    });

    test('rejects an implementation that only implements it', () {
      expect(
        () => EarshotCapturePlatform.instance =
            _ImplementsOnlyEarshotCapturePlatform(),
        throwsA(isA<AssertionError>()),
      );
    });

    group('default methods', () {
      late EarshotCapturePlatform platform;

      setUp(() => platform = _ExtendingEarshotCapturePlatform());

      test('microphonePermissionStatus completes with an error', () {
        expect(platform.microphonePermissionStatus(), throwsA(_notImplemented));
      });

      test('requestMicrophonePermission completes with an error', () {
        expect(
          platform.requestMicrophonePermission(),
          throwsA(_notImplemented),
        );
      });

      test('pcm returns a stream that errors', () {
        expect(
          platform.pcm(const CaptureConfig()),
          emitsError(_notImplemented),
        );
      });

      test('stateChanges returns a stream that errors', () {
        expect(platform.stateChanges(), emitsError(_notImplemented));
      });
    });
  });

  group(UnsupportedEarshotCapture, () {
    late UnsupportedEarshotCapture platform;

    setUp(() => platform = UnsupportedEarshotCapture());

    test('completes every call with an error', () {
      expect(platform.microphonePermissionStatus(), throwsA(_notImplemented));
      expect(platform.requestMicrophonePermission(), throwsA(_notImplemented));
      expect(platform.pcm(const CaptureConfig()), emitsError(_notImplemented));
      expect(platform.stateChanges(), emitsError(_notImplemented));
    });
  });
}
