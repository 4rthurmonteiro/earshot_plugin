import 'package:earshot_classifier_darwin/earshot_classifier_darwin.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(EarshotClassifierDarwin, () {
    late EarshotClassifierPlatform initialInstance;

    setUpAll(() => initialInstance = EarshotClassifierPlatform.instance);
    tearDown(() => EarshotClassifierPlatform.instance = initialInstance);

    test('registerWith sets the platform instance', () {
      EarshotClassifierDarwin.registerWith();
      expect(
        EarshotClassifierPlatform.instance,
        isA<EarshotClassifierDarwin>(),
      );
    });

    test('detections returns a stream that errors', () {
      expect(
        EarshotClassifierDarwin().detections(),
        emitsError(isA<UnimplementedError>()),
      );
    });
  });
}
