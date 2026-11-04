// Loads the real bundled model with LiteRT's native library.
//
// Runs as its own suite: it changes the working directory, which very_good's
// test optimization would share with other suites.
@Tags(['skip_very_good_optimization'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_interpreter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

/// Serves the bundled model from the package directory.
class _FileAssetBundle extends CachingAssetBundle {
  new(this.root);

  final String root;
  final List<String> keys = [];

  @override
  Future<ByteData> load(String key) async {
    keys.add(key);
    final bytes = File('$root/assets/${key.split('/').last}').readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late Directory packageDirectory;
  late _FileAssetBundle bundle;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    packageDirectory = Directory.current;
    // Under `flutter test`, flutter_litert finds its native library through
    // `.dart_tool/package_config.json` in the working directory. In a pub
    // workspace that file lives at the workspace root only, three levels up,
    // and the library is opened again in the inference isolate, so the root
    // stays the working directory for this whole suite.
    Directory.current = packageDirectory.parent.parent.parent;
  });

  tearDownAll(() => Directory.current = packageDirectory);

  // A fresh bundle per test, so recorded keys don't depend on test order.
  setUp(() => bundle = _FileAssetBundle(packageDirectory.path));

  group(LiteRtYamnetInterpreter, () {
    test('loads the bundled model and scores a window', () async {
      final interpreter = await LiteRtYamnetInterpreter.load(bundle: bundle);
      addTearDown(interpreter.close);
      expect(bundle.keys, [LiteRtYamnetInterpreter.assetKey]);

      final scores = await interpreter.run(Float32List(15600));
      expect(scores, hasLength(521));
      final top = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
      expect(top, yamnetIndex('Silence'));
    });

    test('closes only once', () async {
      final interpreter = await LiteRtYamnetInterpreter.load(bundle: bundle);
      await interpreter.close();
      await interpreter.close();
    });
  });

  test('recognizes a 1 kHz tone at 48 kHz as a beep, end to end', () async {
    final original = yamnetInterpreterLoader;
    yamnetInterpreterLoader = () =>
        LiteRtYamnetInterpreter.load(bundle: bundle);
    addTearDown(() => yamnetInterpreterLoader = original);

    final detections = await const EarshotClassifier()
        .classify(
          Stream.fromIterable([
            for (var second = 0; second < 2; second++)
              sineChunk(
                rate: SampleRate.hz48000,
                timestamp: Duration(seconds: second),
              ),
          ]),
        )
        .toList();

    // 2 s give 3 windows: the first is a hit, the next two are confirmed.
    expect(detections, hasLength(2));
    for (final detection in detections) {
      expect(detection.sound, EarshotSound.beep);
      expect(detection.group, SoundGroup.alarms);
      expect(detection.rawLabel, 'Beep, bleep');
      expect(detection.confidence, greaterThan(0.5));
    }
  });
}
