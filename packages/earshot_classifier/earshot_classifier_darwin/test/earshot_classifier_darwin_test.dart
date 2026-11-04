import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier_darwin/earshot_classifier_darwin.dart';
import 'package:earshot_classifier_darwin/src/messages.g.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotClassifierHostApi extends Mock
    implements EarshotClassifierHostApi;

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

SoundDetection _detection(String label, double confidence, int micros) =>
    const SoundVocabulary().detection(
      backend: ClassifierBackend.apple,
      rawLabel: label,
      confidence: confidence,
      timestamp: Duration(microseconds: micros),
    )!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(
    () => registerFallbackValue(
      ClassifierSessionMessage(sessionId: 0, minConfidence: 0),
    ),
  );

  group(EarshotClassifierDarwin, () {
    late EarshotClassifierHostApi hostApi;
    late StreamController<ClassifierEventMessage> events;
    late EarshotClassifierDarwin platform;
    late EarshotClassifierPlatform initialInstance;

    setUpAll(() => initialInstance = EarshotClassifierPlatform.instance);
    tearDown(() => EarshotClassifierPlatform.instance = initialInstance);

    setUp(() {
      hostApi = _MockEarshotClassifierHostApi();
      events = StreamController.broadcast();
      when(() => hostApi.startSession(any())).thenAnswer((_) async {});
      when(() => hostApi.stopSession(any())).thenAnswer((_) async {});
      platform = EarshotClassifierDarwin(
        hostApi: hostApi,
        eventMessages: events.stream,
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

    group('detections', () {
      test('starts a session with the config on listen', () async {
        final subscription = platform
            .detections(const ClassifierConfig(minConfidence: 0.3))
            .listen((_) {});
        await pumpEventQueue();

        final session =
            verify(() => hostApi.startSession(captureAny())).captured.single
                as ClassifierSessionMessage;
        expect(session.minConfidence, 0.3);
        verifyNever(() => hostApi.stopSession(any()));

        await subscription.cancel();
        verify(() => hostApi.stopSession(session.sessionId)).called(1);
      });

      test('maps classifications to detections of the window', () async {
        final detections = <SoundDetection>[];
        final subscription = platform
            .detections(const ClassifierConfig())
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
        final stream = platform.detections(const ClassifierConfig());
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

      test('maps a start error to a CaptureException and closes', () async {
        when(() => hostApi.startSession(any())).thenAnswer(
          (_) => Future.error(
            PlatformException(code: 'permissionDenied', message: 'denied'),
          ),
        );

        await expectLater(
          platform.detections(const ClassifierConfig()),
          emitsInOrder([
            emitsError(
              const CaptureException(
                CaptureErrorCode.permissionDenied,
                'denied',
              ),
            ),
            emitsDone,
          ]),
        );
        verifyNever(() => hostApi.stopSession(any()));
      });

      test('maps an unknown start error code to unknown', () async {
        when(() => hostApi.startSession(any()))
            .thenAnswer((_) => Future.error(PlatformException(code: 'weird')));

        await expectLater(
          platform.detections(const ClassifierConfig()),
          emitsError(const CaptureException(CaptureErrorCode.unknown)),
        );
      });

      test('maps other start errors to unknown', () async {
        when(() => hostApi.startSession(any()))
            .thenAnswer((_) => Future.error(StateError('boom')));

        await expectLater(
          platform.detections(const ClassifierConfig()),
          emitsError(
            const CaptureException(CaptureErrorCode.unknown, 'Bad state: boom'),
          ),
        );
      });

      test('ends the session on an error event', () async {
        final stream = platform.detections(const ClassifierConfig());
        final expectation = expectLater(
          stream,
          emitsInOrder([
            _detection('dog_bark', 0.9, 0),
            emitsError(
              const CaptureException(CaptureErrorCode.audioUnavailable, 'gone'),
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
              errorCode: 'audioUnavailable',
              errorMessage: 'gone',
            ),
          )
          // Ignored after the error.
          ..add(_window(0, 500000, {'dog_bark': 0.9}));
        await expectation;
      });

      test('maps an unknown error event code to unknown', () async {
        final expectation = expectLater(
          platform.detections(const ClassifierConfig()),
          emitsError(const CaptureException(CaptureErrorCode.unknown)),
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

      test('forwards event channel errors as CaptureExceptions', () async {
        final expectation = expectLater(
          platform.detections(const ClassifierConfig()),
          emitsInOrder([
            emitsError(
              const CaptureException(CaptureErrorCode.unknown, 'broken'),
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

      test('passes CaptureExceptions through unchanged', () async {
        const error = CaptureException(CaptureErrorCode.audioUnavailable);
        final expectation = expectLater(
          platform.detections(const ClassifierConfig()),
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
            .detections(const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        await expectLater(subscription.cancel(), completes);
      });

      test('stops a session cancelled before it started', () async {
        final start = Completer<void>();
        when(() => hostApi.startSession(any())).thenAnswer((_) => start.future);
        final subscription = platform
            .detections(const ClassifierConfig())
            .listen((_) {});
        await pumpEventQueue();

        final cancelled = subscription.cancel();
        await pumpEventQueue();
        verifyNever(() => hostApi.stopSession(any()));

        start.complete();
        await cancelled;
        verify(() => hostApi.stopSession(0)).called(1);
      });
    });
  });
}
