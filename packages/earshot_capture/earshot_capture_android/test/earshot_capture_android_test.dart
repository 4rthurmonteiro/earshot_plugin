import 'package:earshot_capture_android/earshot_capture_android.dart';
import 'package:earshot_capture_android/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotCaptureHostApi extends Mock implements EarshotCaptureHostApi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(EarshotCaptureAndroid, () {
    late EarshotCaptureHostApi hostApi;
    late EarshotCaptureAndroid platform;
    late EarshotCapturePlatform initialInstance;

    setUpAll(() => initialInstance = EarshotCapturePlatform.instance);
    tearDown(() => EarshotCapturePlatform.instance = initialInstance);

    setUp(() {
      hostApi = _MockEarshotCaptureHostApi();
      platform = EarshotCaptureAndroid(hostApi: hostApi);
    });

    test('registerWith sets the platform instance', () {
      EarshotCaptureAndroid.registerWith();
      expect(EarshotCapturePlatform.instance, isA<EarshotCaptureAndroid>());
    });

    group('microphonePermissionStatus', () {
      const mapping = {
        PermissionStatusMessage.granted: MicrophonePermissionStatus.granted,
        PermissionStatusMessage.denied: MicrophonePermissionStatus.denied,
        PermissionStatusMessage.undetermined:
            MicrophonePermissionStatus.undetermined,
        PermissionStatusMessage.restricted:
            MicrophonePermissionStatus.restricted,
      };

      for (final MapEntry(key: message, value: status) in mapping.entries) {
        test('maps ${message.name} to ${status.name}', () async {
          when(hostApi.microphonePermissionStatus)
              .thenAnswer((_) async => message);

          await expectLater(
            platform.microphonePermissionStatus(),
            completion(status),
          );
          verify(hostApi.microphonePermissionStatus).called(1);
        });
      }
    });

    test('microphonePermissionStatus forwards host errors', () {
      final error = PlatformException(code: 'channel-error');
      when(hostApi.microphonePermissionStatus).thenThrow(error);

      expect(platform.microphonePermissionStatus(), throwsA(same(error)));
    });

    test('requestMicrophonePermission completes with an error', () {
      expect(
        platform.requestMicrophonePermission(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('pcm returns a stream that errors', () {
      expect(
        platform.pcm(const CaptureConfig()),
        emitsError(isA<UnimplementedError>()),
      );
    });

    test('stateChanges returns a stream that errors', () {
      expect(platform.stateChanges(), emitsError(isA<UnimplementedError>()));
    });
  });
}
