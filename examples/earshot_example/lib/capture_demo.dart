import 'dart:async';
import 'dart:math' as math;

import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';

/// How often the example screens show the latest values while listening, so
/// they can be read during QA.
const kRefreshInterval = Duration(milliseconds: 500);

/// Requests the microphone permission and shows live capture statistics:
/// the capture state, the chunk count and the RMS level in dBFS.
class CaptureDemo extends StatefulWidget {
  /// Creates the capture demo.
  const new({
    this.capture = const EarshotCapture(),
    this.microphonePermission = const MicrophonePermission(),
    super.key,
  });

  /// Streams PCM from the microphone.
  final EarshotCapture capture;

  /// Requests the microphone permission.
  final MicrophonePermission microphonePermission;

  @override
  State<CaptureDemo> createState() => _CaptureDemoState();
}

class _CaptureDemoState extends State<CaptureDemo> {
  String _permission = '';
  String _state = CaptureState.idle.name;
  String _pcm = '';
  int _chunks = 0;
  StreamSubscription<PcmChunk>? _pcmSubscription;
  StreamSubscription<CaptureState>? _stateSubscription;
  Timer? _refresh;

  bool get _capturing => _pcmSubscription != null;

  @override
  void dispose() {
    _refresh?.cancel();
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    super.dispose();
  }

  Future<void> _request() async {
    try {
      final status = await widget.microphonePermission.request();
      if (mounted) setState(() => _permission = status.name);
    } on Object catch (error) {
      if (mounted) setState(() => _permission = 'Error: $error');
    }
  }

  void _start() {
    _chunks = 0;
    // Chunks arrive about 20 times a second; the screen shows the latest
    // values at a readable pace.
    _refresh = Timer.periodic(kRefreshInterval, (_) => setState(() {}));
    _stateSubscription = widget.capture.stateChanges().listen(
      (state) => setState(() => _state = state.name),
      onError: (Object _) {},
    );
    _pcmSubscription = widget.capture.pcm().listen(
      (chunk) {
        _chunks++;
        _pcm =
            '$_chunks chunks, ${_rmsDecibels(chunk).toStringAsFixed(1)} dBFS';
      },
      onError: (Object error) => setState(() => _pcm = 'Error: $error'),
      onDone: () => unawaited(_stop()),
    );
    setState(() {});
  }

  Future<void> _stop() async {
    _refresh?.cancel();
    _refresh = null;
    final cancels = [
      ?_pcmSubscription?.cancel(),
      ?_stateSubscription?.cancel(),
    ];
    _pcmSubscription = null;
    _stateSubscription = null;
    if (mounted) setState(() {});
    await Future.wait(cancels);
  }

  static double _rmsDecibels(PcmChunk chunk) {
    if (chunk.samples.isEmpty) return double.negativeInfinity;
    var sum = 0.0;
    for (final sample in chunk.samples) {
      sum += sample * sample;
    }
    return 10 * math.log(sum / chunk.samples.length) / math.ln10;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Capture', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _request,
          child: const Text('Request permission'),
        ),
        Text(_permission, key: const Key('capturePermission')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _capturing ? _stop : _start,
          child: Text(_capturing ? 'Stop capture' : 'Start capture'),
        ),
        Text(_state, key: const Key('captureState')),
        Text(_pcm, key: const Key('capturePcm')),
      ],
    );
  }
}
