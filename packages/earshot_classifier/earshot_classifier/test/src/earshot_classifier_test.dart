import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fakes.dart';

class _MockEarshotClassifierPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotClassifierPlatform;

SoundDetection _apple(int milliseconds, {double confidence = 0.9}) =>
    SoundDetection(
      group: SoundGroup.alarms,
      sound: EarshotSound.smokeAlarm,
      rawLabel: 'smoke_detector',
      confidence: confidence,
      backend: ClassifierBackend.apple,
      timestamp: Duration(milliseconds: milliseconds),
    );

void main() {
  setUpAll(() => registerFallbackValue(const ClassifierConfig()));

  group(EarshotClassifier, () {
    late _MockEarshotClassifierPlatform platform;
    late StreamController<PcmChunk> pcm;
    late FakeYamnetInterpreter interpreter;
    late EarshotClassifierPlatform initialInstance;
    late EarshotCapturePlatform initialCapture;
    late void Function() restoreInterpreter;

    setUpAll(() {
      initialInstance = EarshotClassifierPlatform.instance;
      initialCapture = EarshotCapturePlatform.instance;
    });

    setUp(() {
      platform = _MockEarshotClassifierPlatform();
      EarshotClassifierPlatform.instance = platform;
      pcm = StreamController<PcmChunk>.broadcast();
      EarshotCapturePlatform.instance = FakeEarshotCapturePlatform(pcm);
      interpreter = FakeYamnetInterpreter();
      restoreInterpreter = useFakeInterpreter(interpreter);
    });

    tearDown(() {
      EarshotClassifierPlatform.instance = initialInstance;
      EarshotCapturePlatform.instance = initialCapture;
      debugDefaultTargetPlatformOverride = null;
      restoreInterpreter();
    });

    /// Feeds [windows] YAMNet windows of silence through the fake capture.
    Future<void> feedWindows(int windows) async {
      await pumpEventQueue();
      pcm.add(silentChunk(15600 + (windows - 1) * 7800));
      await pumpEventQueue();
    }

    test('defaults to the default options', () {
      expect(const EarshotClassifier().options, const ClassifierOptions());
    });

    group('detections', () {
      test('runs YAMNet on captured PCM and smooths it', () async {
        final detections = <SoundDetection>[];
        const EarshotClassifier(
          options: ClassifierOptions(backend: ClassifierBackend.yamnet),
        ).detections().listen(detections.add);
        await feedWindows(3);

        // The first window is the first hit; the next two are confirmed.
        expect(detections.map((detection) => detection.timestamp), [
          const Duration(microseconds: 487500),
          const Duration(microseconds: 975000),
        ]);
        expect(detections.first.sound, EarshotSound.dogBark);
        expect(detections.first.backend, ClassifierBackend.yamnet);
        verifyNever(() => platform.detections(any()));
      });

      test('uses YAMNet for auto off Apple platforms', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final detections = <SoundDetection>[];
        const EarshotClassifier(
          options: ClassifierOptions(smoothing: Smoothing(hits: 1)),
        ).detections().listen(detections.add);
        await feedWindows(1);

        expect(detections, hasLength(1));
        verifyNever(platform.isAvailable);
      });

      for (final target in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        test(
          'uses the platform for auto on ${target.name} when available',
          () async {
            debugDefaultTargetPlatformOverride = target;
            when(platform.isAvailable).thenAnswer((_) async => true);
            when(
              () => platform.detections(any()),
            ).thenAnswer((_) => Stream.fromIterable([_apple(0), _apple(500)]));

            await expectLater(
              const EarshotClassifier(
                options: ClassifierOptions(minConfidence: 0.7),
              ).detections(),
              emitsInOrder([_apple(500), emitsDone]),
            );
            verify(
              () => platform.detections(
                const ClassifierConfig(minConfidence: 0.7),
              ),
            ).called(1);
          },
        );
      }

      test(
        'falls back to YAMNet for auto when the platform is unavailable',
        () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(platform.isAvailable).thenAnswer((_) async => false);
          final detections = <SoundDetection>[];
          const EarshotClassifier(
            options: ClassifierOptions(smoothing: Smoothing(hits: 1)),
          ).detections().listen(detections.add);
          await feedWindows(1);

          expect(detections.single.backend, ClassifierBackend.yamnet);
          verifyNever(() => platform.detections(any()));
        },
      );

      test(
        'falls back to YAMNet for auto when the platform cannot tell',
        () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          when(platform.isAvailable)
              .thenAnswer((_) => Future.error(UnimplementedError()));
          final detections = <SoundDetection>[];
          const EarshotClassifier(
            options: ClassifierOptions(smoothing: Smoothing(hits: 1)),
          ).detections().listen(detections.add);
          await feedWindows(1);

          expect(detections.single.backend, ClassifierBackend.yamnet);
        },
      );

      test('uses the platform for apple on iOS', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => platform.detections(any()))
            .thenAnswer((_) => Stream.value(_apple(0)));

        await expectLater(
          const EarshotClassifier(
            options: ClassifierOptions(
              backend: ClassifierBackend.apple,
              smoothing: Smoothing(hits: 1),
            ),
          ).detections(),
          emitsInOrder([_apple(0), emitsDone]),
        );
        verifyNever(platform.isAvailable);
      });

      test('errors for apple off Apple platforms', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        await expectLater(
          const EarshotClassifier(
            options: ClassifierOptions(backend: ClassifierBackend.apple),
          ).detections(),
          emitsInOrder([emitsError(isA<UnsupportedError>()), emitsDone]),
        );
      });

      test('drops detections below the threshold', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => platform.detections(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _apple(0, confidence: 0.4),
            _apple(500, confidence: 0.6),
          ]),
        );

        await expectLater(
          const EarshotClassifier(
            options: ClassifierOptions(
              backend: ClassifierBackend.apple,
              smoothing: Smoothing(hits: 1),
            ),
          ).detections(),
          emitsInOrder([_apple(500, confidence: 0.6), emitsDone]),
        );
      });

      test('forwards backend errors', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => platform.detections(any()))
            .thenAnswer((_) => Stream.error(StateError('denied')));

        await expectLater(
          const EarshotClassifier(
            options: ClassifierOptions(backend: ClassifierBackend.apple),
          ).detections(),
          emitsInOrder([emitsError(isA<StateError>()), emitsDone]),
        );
      });

      test('stops the backend on cancel', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final native = StreamController<SoundDetection>();
        when(() => platform.detections(any())).thenAnswer((_) => native.stream);

        final subscription = const EarshotClassifier(
          options: ClassifierOptions(backend: ClassifierBackend.apple),
        ).detections().listen(null);
        await pumpEventQueue();
        expect(native.hasListener, isTrue);

        subscription.pause();
        expect(native.isPaused, isTrue);
        subscription.resume();
        expect(native.isPaused, isFalse);

        await subscription.cancel();
        expect(native.hasListener, isFalse);
      });

      test(
        'never starts the backend when cancelled while choosing it',
        () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          final available = Completer<bool>();
          when(platform.isAvailable).thenAnswer((_) => available.future);

          final subscription = const EarshotClassifier().detections().listen(
            null,
          );
          await pumpEventQueue();
          await subscription.cancel();
          available.complete(false);
          await pumpEventQueue();

          expect(pcm.hasListener, isFalse);
          expect(interpreter.windows, isEmpty);
        },
      );

      test('ignores a failure to choose the backend after cancel', () async {
        restoreInterpreter();
        final ready = Completer<void>();
        restoreInterpreter = useFakeInterpreter(
          interpreter,
          ready: ready.future,
          error: StateError('no model'),
        );
        final errors = <Object>[];

        final subscription = const EarshotClassifier(
          options: ClassifierOptions(backend: ClassifierBackend.yamnet),
        ).detections().listen(null, onError: errors.add);
        await pumpEventQueue();
        await subscription.cancel();
        ready.complete();
        await pumpEventQueue();

        expect(errors, isEmpty);
      });
    });

    group('classify', () {
      test('runs YAMNet on the given PCM, resampled', () async {
        final detections = <SoundDetection>[];
        const EarshotClassifier(
          options: ClassifierOptions(smoothing: Smoothing(hits: 1)),
        ).classify(pcm.stream).listen(detections.add);
        await pumpEventQueue();
        pcm.add(sineChunk(rate: SampleRate.hz48000));
        await pumpEventQueue();

        expect(detections, hasLength(1));
        expect(detections.single.backend, ClassifierBackend.yamnet);
        verifyNever(() => platform.detections(any()));
      });

      test('errors for the apple backend', () async {
        await expectLater(
          const EarshotClassifier(
            options: ClassifierOptions(backend: ClassifierBackend.apple),
          ).classify(pcm.stream),
          emitsInOrder([emitsError(isA<UnsupportedError>()), emitsDone]),
        );
      });
    });
  });
}
