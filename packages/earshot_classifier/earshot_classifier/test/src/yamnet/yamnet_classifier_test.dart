import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

const _window = Duration(microseconds: 487500);

void main() {
  group('yamnetDetections', () {
    test('maps scores above the threshold to detections', () {
      final detections = yamnetDetections(
        yamnetScores({'Bark': 0.8, 'Animal': 0.6, 'Speech': 0.4}),
        timestamp: _window,
        minConfidence: 0.5,
      );
      expect(detections, [
        SoundDetection(
          group: SoundGroup.animals,
          sound: EarshotSound.dogBark,
          rawLabel: 'Bark',
          confidence: yamnetScores({'Bark': 0.8})[yamnetIndex('Bark')],
          backend: ClassifierBackend.yamnet,
          timestamp: _window,
        ),
        SoundDetection(
          group: SoundGroup.animals,
          rawLabel: 'Animal',
          confidence: yamnetScores({'Animal': 0.6})[yamnetIndex('Animal')],
          backend: ClassifierBackend.yamnet,
          timestamp: _window,
        ),
      ]);
    });

    test('keeps the best label of each sound', () {
      final detections = yamnetDetections(
        yamnetScores({'Bark': 0.6, 'Bow-wow': 0.7, 'Yip': 0.65}),
        timestamp: Duration.zero,
        minConfidence: 0.5,
      );
      expect(detections, hasLength(1));
      expect(detections.single.sound, EarshotSound.dogBark);
      expect(detections.single.rawLabel, 'Bow-wow');
    });

    test('drops silence', () {
      expect(
        yamnetDetections(
          yamnetScores({'Silence': 0.99}),
          timestamp: Duration.zero,
          minConfidence: 0.5,
        ),
        isEmpty,
      );
    });

    test('keeps a score equal to the threshold', () {
      expect(
        yamnetDetections(
          yamnetScores({'Bark': 0.5}),
          timestamp: Duration.zero,
          minConfidence: 0.5,
        ),
        hasLength(1),
      );
    });
  });

  group('classifyWithYamnet', () {
    late FakeYamnetInterpreter interpreter;
    late StreamController<PcmChunk> pcm;
    late void Function() restore;

    setUp(() {
      interpreter = FakeYamnetInterpreter();
      pcm = StreamController<PcmChunk>();
      restore = useFakeInterpreter(interpreter);
    });

    tearDown(() => restore());

    Stream<SoundDetection> classify() =>
        classifyWithYamnet(() => pcm.stream, const ClassifierConfig());

    test('classifies each window and closes the model when PCM ends', () async {
      final detections = <SoundDetection>[];
      final done = Completer<void>();
      classify().listen(detections.add, onDone: done.complete);
      await pumpEventQueue();
      pcm
        ..add(silentChunk(16000))
        ..add(silentChunk(15200));
      await pcm.close();
      await done.future;

      expect(interpreter.windows, hasLength(3));
      expect(detections.map((detection) => detection.timestamp), [
        Duration.zero,
        _window,
        _window * 2,
      ]);
      expect(detections.first.sound, EarshotSound.dogBark);
      expect(interpreter.closeCount, 1);
    });

    test('reports a model that fails to load', () async {
      restore();
      restore = useFakeInterpreter(interpreter, error: StateError('no model'));
      await expectLater(
        classify(),
        emitsInOrder([emitsError(isA<StateError>()), emitsDone]),
      );
      expect(pcm.hasListener, isFalse);
    });

    test('reports a failed window and keeps going', () async {
      final events = <Object>[];
      classify().listen(events.add, onError: events.add);
      await pumpEventQueue();
      interpreter.runError = StateError('inference failed');
      pcm.add(silentChunk(15600));
      await pumpEventQueue();
      interpreter.runError = null;
      pcm.add(silentChunk(7800));
      await pumpEventQueue();
      expect(events, [isA<StateError>(), isA<SoundDetection>()]);
    });

    test('forwards PCM errors', () async {
      final errors = <Object>[];
      classify().listen(null, onError: errors.add);
      await pumpEventQueue();
      pcm.addError(StateError('mic failed'));
      await pumpEventQueue();
      expect(errors, [isA<StateError>()]);
    });

    test('stops capture and releases the model on cancel', () async {
      final subscription = classify().listen(null);
      await pumpEventQueue();
      expect(pcm.hasListener, isTrue);
      await subscription.cancel();
      expect(pcm.hasListener, isFalse);
      expect(interpreter.closeCount, 1);
    });

    test('releases the model when cancelled while it loads', () async {
      restore();
      final ready = Completer<void>();
      restore = useFakeInterpreter(interpreter, ready: ready.future);
      final subscription = classify().listen(null);
      await pumpEventQueue();
      await subscription.cancel();
      ready.complete();
      await pumpEventQueue();
      expect(pcm.hasListener, isFalse);
      expect(interpreter.closeCount, 1);
    });

    test('drops a window still running when cancelled', () async {
      final detections = <SoundDetection>[];
      final subscription = classify().listen(detections.add);
      await pumpEventQueue();
      interpreter.gate = Completer<void>();
      pcm.add(silentChunk(15600));
      await pumpEventQueue();
      final cancelled = subscription.cancel();
      interpreter.gate!.complete();
      await cancelled;
      expect(detections, isEmpty);
      expect(interpreter.closeCount, 1);
    });

    test('does not report a failed window after cancel', () async {
      final errors = <Object>[];
      final subscription = classify().listen(null, onError: errors.add);
      await pumpEventQueue();
      interpreter
        ..gate = Completer<void>()
        ..runError = StateError('inference failed');
      pcm.add(silentChunk(15600));
      await pumpEventQueue();
      final cancelled = subscription.cancel();
      interpreter.gate!.complete();
      await cancelled;
      expect(errors, isEmpty);
    });

    test('skips queued windows after cancel', () async {
      final subscription = classify().listen(null);
      await pumpEventQueue();
      interpreter.gate = Completer<void>();
      pcm.add(silentChunk(23400));
      await pumpEventQueue();
      final cancelled = subscription.cancel();
      interpreter.gate!.complete();
      await cancelled;
      expect(interpreter.windows, hasLength(1));
    });

    test('pauses and resumes capture', () async {
      final subscription = classify().listen(null);
      await pumpEventQueue();
      subscription.pause();
      expect(pcm.isPaused, isTrue);
      subscription.resume();
      expect(pcm.isPaused, isFalse);
      await subscription.cancel();
    });
  });
}
