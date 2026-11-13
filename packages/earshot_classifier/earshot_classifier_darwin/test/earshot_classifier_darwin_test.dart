import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier_darwin/earshot_classifier_darwin.dart';
import 'package:earshot_classifier_darwin/src/messages.g.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockEarshotClassifierHostApi extends Mock
    implements EarshotClassifierHostApi;

class _MockEarshotCapturePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotCapturePlatform;

ClassifierEventMessage _window(
  int sessionId,
  int micros,
  Map<String, double> classifications,
) => ClassifierEventMessage(
  sessionId: sessionId,
  timestampMicros: micros,
  classifications: [
    for (final MapEntry(:key, :value) in classifications.entries)
      ClassificationMessage(identifier: key, confidence: value),
  ],
);

PcmChunk _chunk(List<double> samples, {int micros = 0}) => PcmChunk(
  samples: Float32List.fromList(samples),
  sampleRate: SampleRate.hz48000,
  timestamp: Duration(microseconds: micros),
);

SoundDetection _detection(String label, double confidence, int micros) =>
    const SoundVocabulary().detection(
      backend: ClassifierBackend.apple,
      rawLabel: label,
      confidence: confidence,
      timestamp: Duration(microseconds: micros),
    )!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const CaptureConfig());
    registerFallbackValue(
      ClassifierSessionMessage(sessionId: 0, minConfidence: 0),
    );
    registerFallbackValue(
      ClassifierPcmMessage(
        sessionId: 0,
        sampleRate: 0,
        timestampMicros: 0,
        samples: Uint8List(0),
      ),
    );
  });

  group(EarshotClassifierDarwin, () {
    late EarshotClassifierHostApi hostApi;
    late StreamController<ClassifierEventMessage> events;
    late StreamController<PcmChunk> pcm;
    late List<CaptureConfig> opened;
    late EarshotClassifierDarwin platform;
    late EarshotClassifierPlatform initialInstance;

    setUpAll(() => initialInstance = EarshotClassifierPlatform.instance);
    tearDown(() => EarshotClassifierPlatform.instance = initialInstance);

    setUp(() {
      hostApi = _MockEarshotClassifierHostApi();
      events = StreamController.broadcast();
      pcm = StreamController.broadcast();
      opened = [];
      when(() => hostApi.startSession(any())).thenAnswer((_) async {});
      when(() => hostApi.analyze(any())).thenAnswer((_) async {});
      when(() => hostApi.stopSession(any())).thenAnswer((_) async {});
      platform = EarshotClassifierDarwin(
        hostApi: hostApi,
        eventMessages: events.stream,
        openPcm: (config) {
          opened.add(config);
          return pcm.stream;
        },
      );
    });

    test('registerWith sets the platform instance', () {
      EarshotClassifierDarwin.registerWith();
      expect(
        EarshotClassifierPlatform.instance,
        isA<EarshotClassifierDarwin>(),
      );
    });

    test('can be created with the default host API and event stream', () {
      expect(EarshotClassifierDarwin.new, returnsNormally);
    });

    group('isAvailable', () {
      for (final available in [true, false]) {
        test('completes with $available from the host', () async {
          when(hostApi.isAvailable).thenAnswer((_) async => available);

          await expectLater(platform.isAvailable(), completion(available));
          verify(hostApi.isAvailable).called(1);
        });
      }

      test('forwards host errors', () {
        final error = PlatformException(code: 'channel-error');
        when(hostApi.isAvailable).thenAnswer((_) => Future.error(error));

        expect(platform.isAvailable(), throwsA(same(error)));
      });
    });

    group('classify', () {
      test('starts a session with the config on listen', () async {
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig(minConfidence: 0.3))
            .listen((_) {});
        await pumpEventQueue();

        final session =
            verify(() => hostApi.startSession(captureAny())).captured.single
                as ClassifierSessionMessage;
        expect(session.minConfidence, 0.3);
        expect(pcm.hasListener, isTrue);
        verifyNever(() => hostApi.stopSession(any()));

        await subscription.cancel();
        expect(pcm.hasListener, isFalse);
        verify(() => hostApi.stopSession(session.sessionId)).called(1);
      });

      test('sends every chunk to the session', () async {
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        pcm
          ..add(_chunk([0.5, -1]))
          ..add(_chunk([0.25], micros: 41));
        await pumpEventQueue();

        final sent = verify(() => hostApi.analyze(captureAny())).captured
            .cast<ClassifierPcmMessage>();
        expect(sent.map((message) => message.sessionId), [0, 0]);
        expect(sent.map((message) => message.sampleRate), [48000, 48000]);
        expect(sent.map((message) => message.timestampMicros), [0, 41]);
        expect(
          sent.first.samples.buffer.asFloat32List(
            sent.first.samples.offsetInBytes,
            2,
          ),
          [0.5, -1],
        );
        await subscription.cancel();
      });

      test('sends only the bytes of a chunk viewing a larger buffer', () async {
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        final backing = Float32List.fromList([1, 2, 3, 4]);
        pcm.add(
          PcmChunk(
            samples: Float32List.sublistView(backing, 1, 3),
            sampleRate: SampleRate.hz16000,
            timestamp: Duration.zero,
          ),
        );
        await pumpEventQueue();

        final message =
            verify(() => hostApi.analyze(captureAny())).captured.single
                as ClassifierPcmMessage;
        expect(message.samples.lengthInBytes, 8);
        expect(Float32List.sublistView(Uint8List.fromList(message.samples)), [
          2,
          3,
        ]);
        await subscription.cancel();
      });

      test('forwards PCM errors unchanged and stops the session', () async {
        final error = StateError('capture failed');
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsInOrder([emitsError(same(error)), emitsDone]),
        );
        await pumpEventQueue();

        pcm.addError(error);
        await expectation;
        await pumpEventQueue();
        expect(pcm.hasListener, isFalse);
        verify(() => hostApi.stopSession(0)).called(1);
      });

      test('closes when the PCM closes and stops the session', () async {
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsDone,
        );
        await pumpEventQueue();

        await pcm.close();
        await expectation;
        await pumpEventQueue();
        verify(() => hostApi.stopSession(0)).called(1);
      });

      test('maps an analyze error to a ClassifierException', () async {
        when(() => hostApi.analyze(any())).thenAnswer(
          (_) => Future.error(PlatformException(code: 'channel-error')),
        );
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsInOrder([
            emitsError(const ClassifierException(ClassifierErrorCode.unknown)),
            emitsDone,
          ]),
        );
        await pumpEventQueue();

        pcm.add(_chunk([0]));
        await expectation;
      });

      test('pausing pauses the PCM', () async {
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        subscription.pause();
        pcm.add(_chunk([0]));
        await pumpEventQueue();
        verifyNever(() => hostApi.analyze(any()));

        subscription.resume();
        await pumpEventQueue();
        verify(() => hostApi.analyze(any())).called(1);
        await subscription.cancel();
      });

      test('keeps the PCM paused when paused before the start', () async {
        final start = Completer<void>();
        when(() => hostApi.startSession(any())).thenAnswer((_) => start.future);
        final subscription =
            platform
                .classify(pcm.stream, const ClassifierConfig())
                .listen((_) {})
              ..pause();
        start.complete();
        await pumpEventQueue();

        pcm.add(_chunk([0]));
        await pumpEventQueue();
        verifyNever(() => hostApi.analyze(any()));

        subscription.resume();
        await pumpEventQueue();
        verify(() => hostApi.analyze(any())).called(1);
        await subscription.cancel();
      });

      test('maps classifications to detections of the window', () async {
        final detections = <SoundDetection>[];
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen(detections.add);
        await pumpEventQueue();

        events
          ..add(_window(0, 500000, {'dog_bark': 0.9, 'speech': 0.6}))
          // Never reported.
          ..add(_window(0, 1000000, {'silence': 0.99}));
        await pumpEventQueue();

        expect(detections, [
          _detection('dog_bark', 0.9, 500000),
          _detection('speech', 0.6, 500000),
        ]);
        expect(detections.first.sound, EarshotSound.dogBark);
        await subscription.cancel();
      });

      test('gives each listen its own session', () async {
        final first = <SoundDetection>[];
        final second = <SoundDetection>[];
        final stream = platform.classify(pcm.stream, const ClassifierConfig());
        final firstSubscription = stream.listen(first.add);
        final secondSubscription = stream.listen(second.add);
        await pumpEventQueue();

        final ids = verify(() => hostApi.startSession(captureAny())).captured
            .cast<ClassifierSessionMessage>()
            .map((session) => session.sessionId)
            .toList();
        expect(ids.toSet(), hasLength(2));

        events
          ..add(_window(ids[0], 0, {'dog_bark': 0.9}))
          ..add(_window(ids[1], 0, {'speech': 0.8}))
          ..add(_window(99, 0, {'cat_meow': 0.8}));
        await pumpEventQueue();

        expect(first, [_detection('dog_bark', 0.9, 0)]);
        expect(second, [_detection('speech', 0.8, 0)]);

        await firstSubscription.cancel();
        verify(() => hostApi.stopSession(ids[0])).called(1);
        verifyNever(() => hostApi.stopSession(ids[1]));
        await secondSubscription.cancel();
        verify(() => hostApi.stopSession(ids[1])).called(1);
      });

      test('maps a start error to a ClassifierException and closes', () async {
        when(() => hostApi.startSession(any())).thenAnswer(
          (_) => Future.error(
            PlatformException(code: 'unsupported', message: 'too old'),
          ),
        );

        await expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsInOrder([
            emitsError(
              const ClassifierException(
                ClassifierErrorCode.unsupported,
                'too old',
              ),
            ),
            emitsDone,
          ]),
        );
        expect(pcm.hasListener, isFalse);
        verifyNever(() => hostApi.stopSession(any()));
      });

      test('maps an unknown start error code to unknown', () async {
        when(() => hostApi.startSession(any()))
            .thenAnswer((_) => Future.error(PlatformException(code: 'weird')));

        await expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsError(const ClassifierException(ClassifierErrorCode.unknown)),
        );
      });

      test('maps other start errors to unknown', () async {
        when(() => hostApi.startSession(any()))
            .thenAnswer((_) => Future.error(StateError('boom')));

        await expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsError(
            const ClassifierException(
              ClassifierErrorCode.unknown,
              'Bad state: boom',
            ),
          ),
        );
      });

      test('ends the session on an error event', () async {
        final stream = platform.classify(pcm.stream, const ClassifierConfig());
        final expectation = expectLater(
          stream,
          emitsInOrder([
            _detection('dog_bark', 0.9, 0),
            emitsError(
              const ClassifierException(
                ClassifierErrorCode.modelUnavailable,
                'gone',
              ),
            ),
            emitsDone,
          ]),
        );
        await pumpEventQueue();

        events
          ..add(_window(0, 0, {'dog_bark': 0.9}))
          ..add(
            ClassifierEventMessage(
              sessionId: 0,
              timestampMicros: 0,
              classifications: [],
              errorCode: 'modelUnavailable',
              errorMessage: 'gone',
            ),
          )
          // Ignored after the error.
          ..add(_window(0, 500000, {'dog_bark': 0.9}));
        await expectation;
      });

      test('maps an unknown error event code to unknown', () async {
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsError(const ClassifierException(ClassifierErrorCode.unknown)),
        );
        await pumpEventQueue();

        events.add(
          ClassifierEventMessage(
            sessionId: 0,
            timestampMicros: 0,
            classifications: [],
            errorCode: 'weird',
          ),
        );
        await expectation;
      });

      test('forwards event channel errors as ClassifierExceptions', () async {
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsInOrder([
            emitsError(
              const ClassifierException(ClassifierErrorCode.unknown, 'broken'),
            ),
            emitsDone,
          ]),
        );
        await pumpEventQueue();

        events
          ..addError(PlatformException(code: 'unknown', message: 'broken'))
          // A second error is ignored.
          ..addError(PlatformException(code: 'unknown'));
        await expectation;
      });

      test('passes ClassifierExceptions through unchanged', () async {
        const error = ClassifierException(ClassifierErrorCode.modelUnavailable);
        final expectation = expectLater(
          platform.classify(pcm.stream, const ClassifierConfig()),
          emitsError(same(error)),
        );
        await pumpEventQueue();

        events.addError(error);
        await expectation;
      });

      test('ignores stop errors on cancel', () async {
        when(() => hostApi.stopSession(any()))
            .thenAnswer((_) => Future.error(PlatformException(code: 'gone')));
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        await expectLater(subscription.cancel(), completes);
      });

      test('stops a session cancelled before it started', () async {
        final start = Completer<void>();
        when(() => hostApi.startSession(any())).thenAnswer((_) => start.future);
        final subscription = platform
            .classify(pcm.stream, const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        final cancelled = subscription.cancel();
        await pumpEventQueue();
        verifyNever(() => hostApi.stopSession(any()));

        start.complete();
        await cancelled;
        expect(pcm.hasListener, isFalse);
        verify(() => hostApi.stopSession(0)).called(1);
      });
    });

    group('detections', () {
      test('uses the capture platform registered after it', () async {
        final initialCapture = EarshotCapturePlatform.instance;
        addTearDown(() => EarshotCapturePlatform.instance = initialCapture);
        final darwin = EarshotClassifierDarwin(
          hostApi: hostApi,
          eventMessages: events.stream,
        );
        final capture = _MockEarshotCapturePlatform();
        when(() => capture.pcm(any())).thenAnswer((_) => pcm.stream);
        EarshotCapturePlatform.instance = capture;

        final subscription = darwin
            .detections(const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        verify(() => capture.pcm(const CaptureConfig())).called(1);
        expect(pcm.hasListener, isTrue);
        await subscription.cancel();
      });

      test('classifies 16 kHz PCM from earshot_capture', () async {
        final subscription = platform
            .detections(const ClassifierConfig(minConfidence: 0.4))
            .listen((_) {});
        await pumpEventQueue();

        expect(opened, [const CaptureConfig()]);
        expect(pcm.hasListener, isTrue);
        final session =
            verify(() => hostApi.startSession(captureAny())).captured.single
                as ClassifierSessionMessage;
        expect(session.minConfidence, 0.4);
        await subscription.cancel();
      });
    });
  });
}
