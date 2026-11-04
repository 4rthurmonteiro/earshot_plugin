import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/src/earshot_classifier_yamnet.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  group(EarshotClassifierYamnet, () {
    late EarshotClassifierPlatform initialInstance;
    late EarshotCapturePlatform initialCapture;

    setUpAll(() {
      initialInstance = EarshotClassifierPlatform.instance;
      initialCapture = EarshotCapturePlatform.instance;
    });

    tearDown(() {
      EarshotClassifierPlatform.instance = initialInstance;
      EarshotCapturePlatform.instance = initialCapture;
    });

    test('registerWith sets the platform instance', () {
      EarshotClassifierYamnet.registerWith();
      expect(
        EarshotClassifierPlatform.instance,
        isA<EarshotClassifierYamnet>(),
      );
    });

    test('is always available', () async {
      expect(await EarshotClassifierYamnet().isAvailable(), isTrue);
    });

    test('classifies 16 kHz PCM from earshot_capture', () async {
      final pcm = StreamController<PcmChunk>();
      final capture = FakeEarshotCapturePlatform(pcm);
      EarshotCapturePlatform.instance = capture;
      final restore = useFakeInterpreter(FakeYamnetInterpreter());
      addTearDown(restore);

      final detections = EarshotClassifierYamnet().detections(
        const ClassifierConfig(),
      );
      final first = detections.first;
      await pumpEventQueue();
      pcm.add(silentChunk(15600));

      expect((await first).sound, EarshotSound.dogBark);
      expect(capture.configs, [const CaptureConfig()]);
      expect(pcm.hasListener, isFalse);
    });
  });
}
