import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/src/capture_config.dart';
import 'package:earshot_capture_platform_interface/src/capture_exception.dart';
import 'package:earshot_capture_platform_interface/src/capture_state.dart';
import 'package:earshot_capture_platform_interface/src/pcm_chunk.dart';

/// PCM as a native capture session produces it: mono float32 samples and the
/// time of the first sample since the native session started.
typedef NativePcm = ({Float32List samples, Duration timestamp});

/// {@template capture_multiplexer}
/// Shares one native microphone session between any number of `pcm()`
/// subscriptions. For platform implementations, not for apps.
///
/// - The first subscription listens to the native streams and calls `start`.
/// - Later subscriptions at the same sample rate join the running session.
///   A subscription at a different sample rate gets a
///   [CaptureErrorCode.sampleRateConflict] error and is closed.
/// - When the last subscription is cancelled, it calls `stop`.
/// - Each subscription's timestamps start at zero.
/// - An error on the native PCM stream, or from `start`, is delivered to
///   every subscription, which is then closed, and the session stops.
///
/// Host calls are serialized, so a `stop` never overtakes a `start`.
/// {@endtemplate}
class CaptureMultiplexer {
  /// {@macro capture_multiplexer}
  ///
  /// `nativePcm` and `nativeStates` must be broadcast streams that may be
  /// listened to again after they are cancelled. Their errors, and errors
  /// thrown by `start`, should already be [CaptureException]s.
  new({
    required this._start,
    required this._stop,
    required this._nativePcm,
    required this._nativeStates,
  });

  final Future<void> Function(CaptureConfig config) _start;
  final Future<void> Function() _stop;
  final Stream<NativePcm> _nativePcm;
  final Stream<CaptureState> _nativeStates;

  final List<_Session> _sessions = [];
  final StreamController<CaptureState> _stateChanges =
      StreamController.broadcast();

  CaptureState _state = CaptureState.idle;
  CaptureConfig? _activeConfig;
  StreamSubscription<NativePcm>? _pcmSubscription;
  StreamSubscription<CaptureState>? _stateSubscription;
  int _generation = 0;
  Future<void> _hostCalls = Future.value();

  /// The current state of the shared session.
  CaptureState get state => _state;

  /// Returns a stream whose every `listen()` joins the shared session with
  /// [config], and whose cancellation leaves it.
  Stream<PcmChunk> pcm(CaptureConfig config) {
    late final _Session session;
    final controller = StreamController<PcmChunk>(
      onListen: () => _join(session),
      onCancel: () => _leave(session),
    );
    session = _Session(config, controller);
    return controller.stream;
  }

  /// Returns a stream that emits the current [state] on `listen()`, then
  /// every change.
  Stream<CaptureState> stateChanges() {
    StreamSubscription<CaptureState>? subscription;
    late final StreamController<CaptureState> controller;
    controller = StreamController<CaptureState>(
      onListen: () {
        controller.add(_state);
        subscription = _stateChanges.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  void _join(_Session session) {
    final active = _activeConfig;
    if (active != null && active.sampleRate != session.config.sampleRate) {
      session.controller.addError(
        CaptureException(
          CaptureErrorCode.sampleRateConflict,
          'Capture is already running at ${active.sampleRate.hz} Hz, so it '
          'cannot also deliver ${session.config.sampleRate.hz} Hz.',
        ),
      );
      unawaited(session.controller.close());
      return;
    }
    _sessions.add(session);
    if (active != null) return;

    _activeConfig = session.config;
    final generation = ++_generation;
    // Listen before starting, so that no chunk is lost.
    _pcmSubscription = _nativePcm.listen(
      _onPcm,
      onError: _endAll,
      onDone: _endAll,
    );
    _stateSubscription = _nativeStates.listen(
      _onNativeState,
      onError: (Object _) {},
    );
    unawaited(
      _enqueue(() async {
        try {
          await _start(session.config);
          if (generation == _generation && _state == CaptureState.idle) {
            _setState(CaptureState.capturing);
          }
        } on Object catch (error) {
          if (generation == _generation) _endAll(error);
        }
      }),
    );
  }

  Future<void> _leave(_Session session) async {
    if (!_sessions.remove(session) || _sessions.isNotEmpty) return;
    await _shutDown();
  }

  Future<void> _shutDown() {
    _generation++;
    _activeConfig = null;
    final cancels = [
      ?_pcmSubscription?.cancel(),
      ?_stateSubscription?.cancel(),
    ];
    _pcmSubscription = null;
    _stateSubscription = null;
    _setState(CaptureState.idle);
    return _enqueue(() async {
      try {
        await Future.wait(cancels);
        await _stop();
      } on Object catch (_) {
        // Best effort: the session is over for Dart either way.
      }
    });
  }

  void _onPcm(NativePcm pcm) {
    final sampleRate = _activeConfig!.sampleRate;
    for (final (index, session) in _sessions.indexed) {
      final offset = session.offset ??= pcm.timestamp;
      session.controller.add(
        PcmChunk(
          // Every subscription after the first gets its own copy, so that
          // one listener cannot modify the samples another one sees.
          samples: index == 0 ? pcm.samples : Float32List.fromList(pcm.samples),
          sampleRate: sampleRate,
          timestamp: pcm.timestamp - offset,
        ),
      );
    }
  }

  void _onNativeState(CaptureState state) {
    // Dart owns `idle`: the session ends when the last subscription leaves.
    if (state != CaptureState.idle) _setState(state);
  }

  void _endAll([Object? error]) {
    final sessions = List.of(_sessions);
    _sessions.clear();
    for (final session in sessions) {
      if (error != null) session.controller.addError(error);
      unawaited(session.controller.close());
    }
    unawaited(_shutDown());
  }

  void _setState(CaptureState state) {
    if (state == _state) return;
    _state = state;
    _stateChanges.add(state);
  }

  Future<void> _enqueue(Future<void> Function() call) =>
      _hostCalls = _hostCalls.then((_) => call());
}

class _Session {
  new(this.config, this.controller);

  final CaptureConfig config;
  final StreamController<PcmChunk> controller;
  Duration? offset;
}
