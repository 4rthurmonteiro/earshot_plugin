import 'dart:async';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:earshot_plugin/src/dependencies.dart';
import 'package:earshot_plugin/src/earshot_errors.dart';
import 'package:earshot_plugin/src/earshot_event.dart';
import 'package:earshot_plugin/src/earshot_exception.dart';
import 'package:earshot_plugin/src/earshot_options.dart';
import 'package:flutter/foundation.dart';

/// {@template earshot}
/// Listens to the microphone and reports how loud it is and what is
/// sounding, on-device.
///
/// Audio never leaves the device and is never written to disk. earshot is
/// informational and is not a certified detector: never rely on it for
/// safety, including smoke and carbon monoxide alarms.
/// {@endtemplate}
class Earshot {
  /// {@macro earshot}
  const new();

  /// Starts listening with [options] and returns what earshot hears.
  ///
  /// ## Events
  ///
  /// With level metering on ([EarshotOptions.level] is not `null`), every
  /// [LevelReading] is an [EarshotEvent], which also carries the sounds the
  /// classifier confirmed since the previous event. With level metering off,
  /// every confirmed [SoundDetection] is an event of its own.
  ///
  /// ## Microphone sessions
  ///
  /// Capture runs at [EarshotOptions.capture], 16 kHz by default. One
  /// capture subscription feeds the [LevelMeter] and, when it classifies
  /// PCM, the [EarshotClassifier]. Which path the classifier takes follows
  /// [ClassifierOptions.backend]:
  ///
  /// - [ClassifierBackend.yamnet], and [ClassifierBackend.auto] on Android,
  ///   classify the shared capture stream with
  ///   [EarshotClassifier.classify]. PCM at 44.1 or 48 kHz is resampled to
  ///   the 16 kHz YAMNet expects.
  /// - [ClassifierBackend.apple], and [ClassifierBackend.auto] on iOS and
  ///   macOS, use [EarshotClassifier.detections]. In 0.1.0 Apple
  ///   SoundAnalysis runs its own microphone session next to capture. When
  ///   `auto` finds SoundAnalysis unavailable, the classifier falls back to
  ///   YAMNet on its own 16 kHz capture subscription, which joins the same
  ///   microphone session; with a capture rate other than 16 kHz it then
  ///   fails with [EarshotErrorCode.sampleRateConflict].
  ///
  /// With both [EarshotOptions.level] and [EarshotOptions.classifier] set to
  /// `null`, the stream opens nothing and closes at once.
  ///
  /// ## Subscriptions
  ///
  /// Each call to `listen()` on the returned stream starts its own session,
  /// and cancelling the subscription stops everything it started: capture,
  /// the level meter and the classifier. Pausing the subscription pauses
  /// them too; audio captured meanwhile is buffered in memory, so cancel
  /// rather than pause for long breaks.
  ///
  /// ## Errors
  ///
  /// The stream never throws synchronously. Failures are delivered as one
  /// [EarshotException] stream error, after which the session stops and the
  /// stream closes. [EarshotException.cause] keeps the original error.
  Stream<EarshotEvent> listen({
    EarshotOptions options = const EarshotOptions(),
  }) => Stream.multi((controller) => _Session(options, controller).start());
}

/// One `listen()` of [Earshot.listen].
class _Session {
  new(this._options, this._controller);

  final EarshotOptions _options;
  final MultiStreamController<EarshotEvent> _controller;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<StreamController<PcmChunk>> _pcmOutputs = [];
  List<SoundDetection> _pending = [];
  int _openSources = 0;
  bool _ended = false;

  void start() {
    final levelOptions = _options.level;
    final classifierOptions = _options.classifier;
    if (levelOptions == null && classifierOptions == null) {
      _controller.closeSync();
      return;
    }

    if (levelOptions != null) {
      _listenTo(
        _sharedPcm().transform(LevelMeter(options: levelOptions)),
        _onLevel,
        fromClassifier: false,
      );
    }
    if (classifierOptions != null) {
      final classifier = earshotClassifierFactory(classifierOptions);
      _listenTo(
        _classifiesSharedPcm(classifierOptions.backend)
            ? classifier.classify(_sharedPcm())
            : classifier.detections(),
        _onDetection,
        fromClassifier: true,
      );
    }
    if (_pcmOutputs.isNotEmpty) {
      _subscriptions.add(
        earshotCapture
            .pcm(config: _options.capture)
            .listen(
              _onPcm,
              onError: (Object error, StackTrace stackTrace) =>
                  _fail(error, stackTrace, fromClassifier: false),
              onDone: _closePcmOutputs,
            ),
      );
    }

    _controller
      ..onPause = _pause
      ..onResume = _resume
      ..onCancel = _cancel;
  }

  /// Whether the classifier reads the shared capture stream, rather than
  /// opening its own session.
  static bool _classifiesSharedPcm(ClassifierBackend backend) =>
      switch (backend) {
        ClassifierBackend.yamnet => true,
        ClassifierBackend.apple => false,
        ClassifierBackend.auto => !_isApplePlatform,
      };

  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Returns a new stream fed with every chunk of the one capture
  /// subscription.
  Stream<PcmChunk> _sharedPcm() {
    final output = StreamController<PcmChunk>(sync: true);
    _pcmOutputs.add(output);
    return output.stream;
  }

  void _listenTo<T>(
    Stream<T> stream,
    void Function(T) onData, {
    required bool fromClassifier,
  }) {
    _openSources++;
    _subscriptions.add(
      stream.listen(
        onData,
        onError: (Object error, StackTrace stackTrace) =>
            _fail(error, stackTrace, fromClassifier: fromClassifier),
        onDone: _onSourceDone,
      ),
    );
  }

  void _onPcm(PcmChunk chunk) {
    for (final output in _pcmOutputs) {
      output.add(chunk);
    }
  }

  void _onLevel(LevelReading reading) {
    _controller.addSync(
      EarshotEvent(
        timestamp: reading.timestamp,
        level: reading,
        detections: _takePending(),
      ),
    );
  }

  void _onDetection(SoundDetection detection) {
    if (_options.level != null) {
      _pending.add(detection);
    } else {
      _controller.addSync(
        EarshotEvent(
          timestamp: detection.timestamp,
          detections: List.unmodifiable([detection]),
        ),
      );
    }
  }

  List<SoundDetection> _takePending() {
    final detections = List<SoundDetection>.unmodifiable(_pending);
    _pending = [];
    return detections;
  }

  void _onSourceDone() {
    if (--_openSources > 0 || _ended) return;
    _ended = true;
    // Detections confirmed after the last level reading.
    if (_pending.isNotEmpty) {
      _controller.addSync(
        EarshotEvent(
          timestamp: _pending.last.timestamp,
          detections: _takePending(),
        ),
      );
    }
    _controller.closeSync();
    unawaited(_stop());
  }

  void _fail(
    Object error,
    StackTrace stackTrace, {
    required bool fromClassifier,
  }) {
    if (_ended) return;
    _ended = true;
    _controller
      ..addErrorSync(
        toEarshotException(error, fromClassifier: fromClassifier),
        stackTrace,
      )
      ..closeSync();
    unawaited(_stop());
  }

  void _closePcmOutputs() {
    for (final output in _pcmOutputs) {
      unawaited(output.close());
    }
  }

  void _pause() {
    for (final subscription in _subscriptions) {
      subscription.pause();
    }
  }

  void _resume() {
    for (final subscription in _subscriptions) {
      subscription.resume();
    }
  }

  Future<void> _cancel() {
    _ended = true;
    return _stop();
  }

  Future<void> _stop() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait([
      for (final subscription in subscriptions) subscription.cancel(),
    ]);
  }
}
