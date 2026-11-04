import 'package:earshot_capture_darwin/earshot_capture_darwin.dart';
import 'package:earshot_capture_darwin/src/messages.g.dart';
import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotCaptureHostApi extends Mock implements EarshotCaptureHostApi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(EarshotCaptureDarwin, () {
    late EarshotCaptureHostApi hostApi;
    late EarshotCaptureDarwin platform;

    setUp(() {
      hostApi = _MockEarshotCaptureHostApi();
      platform = EarshotCaptureDarwin(hostApi: hostApi);
    });

    test('registerWith sets the platform instance', () {
      EarshotCaptureDarwin.registerWith();
      expect(EarshotCapturePlatform.instance, isA<EarshotCaptureDarwin>());
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
