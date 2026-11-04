import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(Earshot, () {
    test('listen returns a stream that errors and does not throw', () {
      late Stream<EarshotEvent> stream;
      expect(() => stream = const Earshot().listen(), returnsNormally);
      expect(stream, emitsError(isA<UnimplementedError>()));
    });
  });

  group(EarshotOptions, () {
    test('enables capture, level and classifier by default', () {
      const options = EarshotOptions();
      expect(options.capture, const CaptureConfig());
      expect(options.level, const LevelOptions());
      expect(options.classifier, const ClassifierOptions());
    });

    test('supports value equality', () {
      expect(const EarshotOptions(), const EarshotOptions());
      expect(
        const EarshotOptions(),
        isNot(
          const EarshotOptions(
            capture: CaptureConfig(sampleRate: SampleRate.hz48000),
          ),
        ),
      );
      expect(const EarshotOptions(), isNot(const EarshotOptions(level: null)));
      expect(
        const EarshotOptions(),
        isNot(const EarshotOptions(classifier: null)),
      );
    });

    test('has a consistent hashCode', () {
      expect(const EarshotOptions().hashCode, const EarshotOptions().hashCode);
    });

    test('has a readable toString', () {
      expect(
        const EarshotOptions(level: null, classifier: null).toString(),
        'EarshotOptions(capture: CaptureConfig(sampleRate: '
        'SampleRate.hz16000), level: null, classifier: null)',
      );
    });
  });

  group(EarshotEvent, () {
    const level = LevelReading(
      db: 60,
      leq: 55,
      weighting: Weighting.a,
      timestamp: Duration(seconds: 1),
    );
    const detection = SoundDetection(
      group: SoundGroup.animals,
      rawLabel: 'Dog',
      confidence: 0.9,
      backend: ClassifierBackend.yamnet,
      timestamp: Duration(seconds: 1),
    );
    const other = SoundDetection(
      group: SoundGroup.music,
      rawLabel: 'Guitar',
      confidence: 0.7,
      backend: ClassifierBackend.yamnet,
      timestamp: Duration(seconds: 1),
    );

    EarshotEvent event({
      Duration timestamp = const Duration(seconds: 1),
      LevelReading? level = level,
      List<SoundDetection> detections = const [detection],
    }) => EarshotEvent(
      timestamp: timestamp,
      level: level,
      detections: detections,
    );

    test('defaults to no level and no detections', () {
      const event = EarshotEvent(timestamp: Duration.zero);
      expect(event.level, isNull);
      expect(event.detections, isEmpty);
    });

    test('supports value equality', () {
      final a = event();
      expect(a, a);
      expect(event(), event());
      expect(event(), isNot(event(timestamp: Duration.zero)));
      expect(event(), isNot(event(level: null)));
      expect(event(), isNot(event(detections: const [])));
      expect(event(), isNot(event(detections: const [other])));
      expect(event(), isNot(Object()));
    });

    test('has a consistent hashCode', () {
      expect(event().hashCode, event().hashCode);
    });

    test('has a readable toString', () {
      expect(
        event(level: null, detections: const []).toString(),
        'EarshotEvent(timestamp: 0:00:01.000000, level: null, '
        'detections: [])',
      );
    });
  });

  group(EarshotException, () {
    test('supports value equality', () {
      expect(
        const EarshotException(EarshotErrorCode.unsupported, 'web'),
        const EarshotException(EarshotErrorCode.unsupported, 'web'),
      );
      expect(
        const EarshotException(EarshotErrorCode.unsupported),
        isNot(const EarshotException(EarshotErrorCode.unknown)),
      );
      expect(
        const EarshotException(EarshotErrorCode.unsupported),
        isNot(const EarshotException(EarshotErrorCode.unsupported, 'web')),
      );
    });

    test('has a consistent hashCode', () {
      expect(
        const EarshotException(EarshotErrorCode.unknown).hashCode,
        const EarshotException(EarshotErrorCode.unknown).hashCode,
      );
    });

    test('has a readable toString', () {
      expect(
        const EarshotException(EarshotErrorCode.permissionDenied).toString(),
        'EarshotException(permissionDenied)',
      );
      expect(
        const EarshotException(
          EarshotErrorCode.modelUnavailable,
          'missing',
        ).toString(),
        'EarshotException(modelUnavailable, missing)',
      );
    });
  });
}
