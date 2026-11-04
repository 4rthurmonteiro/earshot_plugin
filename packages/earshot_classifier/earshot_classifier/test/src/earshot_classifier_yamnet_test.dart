import 'package:earshot_classifier/src/earshot_classifier_yamnet.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(EarshotClassifierYamnet, () {
    late EarshotClassifierPlatform initialInstance;

    setUpAll(() => initialInstance = EarshotClassifierPlatform.instance);
    tearDown(() => EarshotClassifierPlatform.instance = initialInstance);

    test('registerWith sets the platform instance', () {
      EarshotClassifierYamnet.registerWith();
      expect(
        EarshotClassifierPlatform.instance,
        isA<EarshotClassifierYamnet>(),
      );
    });

    test('detections returns a stream that errors', () {
      expect(
        EarshotClassifierYamnet().detections(),
        emitsError(isA<UnimplementedError>()),
      );
    });
  });
}
