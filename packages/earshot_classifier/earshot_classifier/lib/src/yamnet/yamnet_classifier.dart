import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_framer.dart';
import 'package:earshot_classifier/src/yamnet/yamnet_interpreter.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:meta/meta.dart';

const _vocabulary = SoundVocabulary();

final List<String> _labels = _vocabulary.labels(ClassifierBackend.yamnet);

/// Turns the 521 YAMNet [scores] of the window at [timestamp] into
/// detections.
///
/// Labels scored below [minConfidence] and labels that are never reported
/// are dropped. When several labels map to the same sound, or the same
/// unmapped label appears, only the highest score is kept. The result is
/// sorted by confidence, highest first.
@internal
List<SoundDetection> yamnetDetections(
  Float32List scores, {
  required Duration timestamp,
  required double minConfidence,
}) {
  final best = <Object, SoundDetection>{};
  for (var i = 0; i < scores.length && i < _labels.length; i++) {
    final confidence = scores[i];
    if (confidence < minConfidence) continue;
    final detection = _vocabulary.detection(
      backend: ClassifierBackend.yamnet,
      rawLabel: _labels[i],
      confidence: confidence,
      timestamp: timestamp,
    );
    if (detection == null) continue;
    final key = detection.sound ?? detection.rawLabel;
    final previous = best[key];
    if (previous == null || previous.confidence < confidence) {
      best[key] = detection;
    }
  }
  return best.values.toList()
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
}

/// Classifies the PCM from [openPcm] with YAMNet and returns every detection
/// at or above [ClassifierConfig.minConfidence], window by window, without
/// smoothing.
///
/// Each `listen()` loads its own model, then calls [openPcm] and listens to
/// the stream it returns. Cancelling the subscription cancels that stream
/// and releases the model. Errors from the PCM are forwarded unchanged, and
/// a model that fails to load or run is reported as a [ClassifierException]
/// with [ClassifierErrorCode.modelUnavailable].
@internal
Stream<SoundDetection> classifyWithYamnet(
  Stream<PcmChunk> Function() openPcm,
  ClassifierConfig config,
) => Stream.multi(
  (controller) => _YamnetSession(openPcm, config, controller).start(),
);

class _YamnetSession {
  new(this._openPcm, this._config, this._controller);

  final Stream<PcmChunk> Function() _openPcm;
  final ClassifierConfig _config;
  final MultiStreamController<SoundDetection> _controller;
  final YamnetFramer _framer = YamnetFramer();

  YamnetInterpreter? _interpreter;
  StreamSubscription<PcmChunk>? _subscription;
  Future<void> _inference = Future.value();
  bool _cancelled = false;

  Future<void> start() async {
    _controller.onCancel = _cancel;
    final YamnetInterpreter interpreter;
    try {
      interpreter = await yamnetInterpreterLoader();
    } on Object catch (error, stackTrace) {
      if (!_cancelled) {
        _controller
          ..addError(_modelError(error), stackTrace)
          ..closeSync();
      }
      return;
    }
    if (_cancelled) {
      await interpreter.close();
      return;
    }
    _interpreter = interpreter;
    _subscription = _openPcm().listen(
      _onChunk,
      onError: _controller.addErrorSync,
      onDone: () => _inference.whenComplete(_finish),
    );
    _controller
      ..onPause = _subscription!.pause
      ..onResume = _subscription!.resume;
  }

  void _onChunk(PcmChunk chunk) {
    for (final window in _framer.add(chunk)) {
      _inference = _inference.then((_) => _classify(window));
    }
  }

  Future<void> _classify(YamnetWindow window) async {
    if (_cancelled) return;
    try {
      final scores = await _interpreter!.run(window.samples);
      if (_cancelled) return;
      yamnetDetections(
        scores,
        timestamp: window.timestamp,
        minConfidence: _config.minConfidence,
      ).forEach(_controller.addSync);
    } on Object catch (error, stackTrace) {
      if (!_cancelled) _controller.addErrorSync(_modelError(error), stackTrace);
    }
  }

  Future<void> _finish() async {
    await _release();
    if (!_cancelled) _controller.closeSync();
  }

  Future<void> _cancel() async {
    _cancelled = true;
    await _subscription?.cancel();
    await _inference;
    await _release();
  }

  static ClassifierException _modelError(Object error) =>
      ClassifierException(ClassifierErrorCode.modelUnavailable, '$error');

  /// Closes the model once, whether the PCM ended or the listener cancelled.
  Future<void> _release() async {
    final interpreter = _interpreter;
    _interpreter = null;
    await interpreter?.close();
  }
}
