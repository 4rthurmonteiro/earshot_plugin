import 'dart:async';

import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:earshot_plugin/src/dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotCapture extends Mock implements EarshotCapture;

class _MockEarshotClassifier extends Mock implements EarshotClassifier;

/// 100 ms of silence at 16 kHz, so that its level reading is stamped
/// `milliseconds` + 100 ms.
PcmChunk _chunk(int milliseconds) => PcmChunk(
  samples: Float32List(1600),
  sampleRate: SampleRate.hz16000,
  timestamp: Duration(milliseconds: milliseconds),
);

SoundDetection _detection(int milliseconds) => SoundDetection(
  group: SoundGroup.animals,
  rawLabel: 'Dog',
  confidence: 0.9,
  backend: ClassifierBackend.yamnet,
  timestamp: Duration(milliseconds: milliseconds),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const CaptureConfig());
    registerFallbackValue(const Stream<PcmChunk>.empty());
  });

  group(Earshot, () {
    late _MockEarshotCapture capture;
    late _MockEarshotClassifier classifier;
    late StreamController<PcmChunk> pcm;
    late StreamController<SoundDetection> detections;
    late List<ClassifierOptions> builtWith;
    Stream<PcmChunk>? classified;

    setUp(() {
      pcm = StreamController<PcmChunk>();
      detections = StreamController<SoundDetection>();
      capture = _MockEarshotCapture();
      when(() => capture.pcm(config: any(named: 'config')))
          .thenAnswer((_) => pcm.stream);
      classifier = _MockEarshotClassifier();
      classified = null;
      when(() => classifier.classify(any())).thenAnswer((invocation) {
        classified = invocation.positionalArguments.first as Stream<PcmChunk>;
        return detections.stream;
      });
      when(classifier.detections).thenAnswer((_) => detections.stream);
      builtWith = [];
      earshotCapture = capture;
      earshotClassifierFactory = (options) {
        builtWith.add(options);
        return classifier;
      };
    });

    tearDown(() {
      earshotCapture = const EarshotCapture();
      earshotClassifierFactory = defaultClassifierFactory;
      debugDefaultTargetPlatformOverride = null;
    });

    EarshotOptions options({
      CaptureConfig capture = const CaptureConfig(),
      LevelOptions? level = const LevelOptions(),
      ClassifierBackend? backend = ClassifierBackend.yamnet,
    }) => EarshotOptions(
      capture: capture,
      level: level,
      classifier: backend == null
          ? null
          : ClassifierOptions(backend: backend, minConfidence: 0.3),
    );

    test('listen does not throw synchronously', () {
      expect(() => const Earshot().listen(), returnsNormally);
      verifyNever(() => capture.pcm(config: any(named: 'config')));
    });

    test('the default classifier factory passes the options on', () {
      const classifierOptions = ClassifierOptions(minConfidence: 0.7);
      expect(
        defaultClassifierFactory(classifierOptions).options,
        classifierOptions,
      );
    });

    test('closes at once and opens nothing without level or classifier', () {
      final stream = const Earshot().listen(
        options: options(level: null, backend: null),
      );
      expect(stream, emitsDone);
      verifyNever(() => capture.pcm(config: any(named: 'config')));
      expect(builtWith, isEmpty);
    });

    test('meters the level of the capture stream', () async {
      const config = CaptureConfig(sampleRate: SampleRate.hz48000);
      final events = <EarshotEvent>[];
      final subscription = const Earshot()
          .listen(options: options(capture: config, backend: null))
          .listen(events.add);

      pcm
        ..add(_chunk(0))
        ..add(_chunk(100));
      await pumpEventQueue();

      verify(() => capture.pcm(config: config)).called(1);
      expect(builtWith, isEmpty);
      expect(events.map((e) => e.timestamp), const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
      expect(events.map((e) => e.level?.timestamp), const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
      expect(events.every((e) => e.detections.isEmpty), isTrue);
      await subscription.cancel();
    });

    test(
      'feeds the same capture stream to YAMNet and the level meter',
      () async {
        final events = <EarshotEvent>[];
        final subscription = const Earshot()
            .listen(options: options())
            .listen(events.add);
        final classifiedChunks = <PcmChunk>[];
        classified!.listen(classifiedChunks.add);

        final first = _chunk(0);
        pcm.add(first);
        detections
          ..add(_detection(10))
          ..add(_detection(20));
        await pumpEventQueue();
        pcm.add(_chunk(100));
        await pumpEventQueue();

        verify(() => capture.pcm()).called(1);
        verifyNever(classifier.detections);
        expect(builtWith, [options().classifier]);
        expect(classifiedChunks, [first, _chunk(100)]);
        expect(identical(classifiedChunks.first, first), isTrue);
        expect(events, hasLength(2));
        expect(events[0].detections, isEmpty);
        expect(events[1].detections, [_detection(10), _detection(20)]);
        expect(events[1].level, isNotNull);
        expect(() => events[1].detections.clear(), throwsUnsupportedError);
        await subscription.cancel();
      },
    );

    test('emits an event per detection when level metering is off', () async {
      final events = <EarshotEvent>[];
      final subscription = const Earshot()
          .listen(options: options(level: null))
          .listen(events.add);

      detections.add(_detection(975));
      await pumpEventQueue();

      verify(() => capture.pcm()).called(1);
      expect(classified, isNotNull);
      expect(events, [
        EarshotEvent(
          timestamp: const Duration(milliseconds: 975),
          detections: [_detection(975)],
        ),
      ]);
      expect(() => events.single.detections.clear(), throwsUnsupportedError);
      await subscription.cancel();
    });

    test('uses detections for the apple backend', () async {
      final events = <EarshotEvent>[];
      final subscription = const Earshot()
          .listen(options: options(backend: ClassifierBackend.apple))
          .listen(events.add);

      detections.add(_detection(500));
      pcm.add(_chunk(0));
      await pumpEventQueue();

      verify(classifier.detections).called(1);
      verifyNever(() => classifier.classify(any()));
      expect(events.single.detections, [_detection(500)]);
      await subscription.cancel();
    });

    test('opens no capture for apple without level metering', () async {
      final subscription = const Earshot()
          .listen(
            options: options(level: null, backend: ClassifierBackend.apple),
          )
          .listen((_) {});
      await pumpEventQueue();

      verify(classifier.detections).called(1);
      verifyNever(() => capture.pcm(config: any(named: 'config')));
      await subscription.cancel();
    });

    test('auto classifies the shared capture stream on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final subscription = const Earshot()
          .listen(options: options(backend: ClassifierBackend.auto))
          .listen((_) {});
      await pumpEventQueue();

      verify(() => classifier.classify(any())).called(1);
      verifyNever(classifier.detections);
      await subscription.cancel();
    });

    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      test('auto leaves backend selection to the classifier on '
          '${platform.name}', () async {
        debugDefaultTargetPlatformOverride = platform;
        final subscription = const Earshot()
            .listen(options: options(backend: ClassifierBackend.auto))
            .listen((_) {});
        await pumpEventQueue();

        verify(classifier.detections).called(1);
        verifyNever(() => classifier.classify(any()));
        await subscription.cancel();
      });
    }

    test(
      'maps a capture error, ends the stream and stops everything',
      () async {
        final stream = const Earshot().listen(options: options());
        final expectation = expectLater(
          stream,
          emitsInOrder([
            emitsError(
              const EarshotException(
                EarshotErrorCode.permissionDenied,
                'denied',
                CaptureException(CaptureErrorCode.permissionDenied, 'denied'),
              ),
            ),
            emitsDone,
          ]),
        );
        await pumpEventQueue();
        pcm.addError(
          const CaptureException(CaptureErrorCode.permissionDenied, 'denied'),
        );
        await expectation;
        await pumpEventQueue();

        expect(pcm.hasListener, isFalse);
        expect(detections.hasListener, isFalse);
      },
    );

    test(
      'maps a classifier error, ends the stream and stops capture',
      () async {
        final error = StateError('no model');
        final stream = const Earshot().listen(options: options());
        final expectation = expectLater(
          stream,
          emitsInOrder([
            emitsError(
              EarshotException(
                EarshotErrorCode.modelUnavailable,
                '$error',
                error,
              ),
            ),
            emitsDone,
          ]),
        );
        await pumpEventQueue();
        detections.addError(error);
        await expectation;
        await pumpEventQueue();

        expect(pcm.hasListener, isFalse);
      },
    );

    test('closes when capture ends, after the last detections', () async {
      final events = <EarshotEvent>[];
      final done = Completer<void>();
      const Earshot()
          .listen(options: options())
          .listen(events.add, onDone: done.complete);

      pcm.add(_chunk(0));
      await pumpEventQueue();
      detections.add(_detection(900));
      await pcm.close();
      await pumpEventQueue();
      expect(done.isCompleted, isFalse);
      await detections.close();
      await done.future;

      expect(events.map((e) => e.level == null), [false, true]);
      expect(
        events.last,
        EarshotEvent(
          timestamp: const Duration(milliseconds: 900),
          detections: [_detection(900)],
        ),
      );
    });

    test('closes without an extra event when nothing is pending', () async {
      final events = <EarshotEvent>[];
      final done = Completer<void>();
      const Earshot()
          .listen(options: options(backend: null))
          .listen(events.add, onDone: done.complete);

      pcm.add(_chunk(0));
      await pcm.close();
      await done.future;

      expect(events, hasLength(1));
    });

    test('cancelling stops capture and the classifier', () async {
      final subscription = const Earshot()
          .listen(options: options(backend: ClassifierBackend.apple))
          .listen((_) {});
      await pumpEventQueue();
      expect(pcm.hasListener, isTrue);
      expect(detections.hasListener, isTrue);

      await subscription.cancel();

      expect(pcm.hasListener, isFalse);
      expect(detections.hasListener, isFalse);
    });

    test('pausing pauses capture and the classifier', () async {
      final subscription = const Earshot()
          .listen(options: options(backend: ClassifierBackend.apple))
          .listen((_) {});
      await pumpEventQueue();

      subscription.pause();
      expect(pcm.isPaused, isTrue);
      expect(detections.isPaused, isTrue);

      subscription.resume();
      expect(pcm.isPaused, isFalse);
      expect(detections.isPaused, isFalse);
      await subscription.cancel();
    });

    test('each listen starts its own session', () async {
      when(() => capture.pcm(config: any(named: 'config')))
          .thenAnswer((_) => const Stream.empty());
      final stream = const Earshot().listen(options: options(backend: null));

      await stream.drain<void>();
      await stream.drain<void>();

      verify(() => capture.pcm(config: any(named: 'config'))).called(2);
    });
  });
}
