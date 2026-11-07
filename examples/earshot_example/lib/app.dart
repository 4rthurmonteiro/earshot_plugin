import 'dart:async';

import 'package:earshot_example/capture_demo.dart';
import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';

/// The earshot version this example demonstrates.
const kEarshotVersion = '0.2.0';

/// How many recent detections the page keeps on screen.
const kMaxDetections = 20;

/// The earshot example app.
class EarshotExampleApp extends StatelessWidget {
  /// Creates the earshot example app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'earshot',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const EarshotPage(),
    );
  }
}

/// Shows the microphone permission status, and starts and stops listening.
class EarshotPage extends StatefulWidget {
  /// Creates the page.
  const new({
    this.earshot = const Earshot(),
    this.microphonePermission = const MicrophonePermission(),
    super.key,
  });

  /// The earshot instance the page listens with.
  final Earshot earshot;

  /// Reads the microphone permission status.
  final MicrophonePermission microphonePermission;

  @override
  State<EarshotPage> createState() => _EarshotPageState();
}

class _EarshotPageState extends State<EarshotPage> {
  String _permission = 'Checking…';
  String _status = 'Not listening';
  String _level = '';
  final List<String> _detections = [];
  StreamSubscription<EarshotEvent>? _subscription;
  Timer? _refresh;

  bool get _listening => _subscription != null;

  @override
  void initState() {
    super.initState();
    unawaited(_readPermission());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _readPermission() async {
    try {
      final status = await widget.microphonePermission.status();
      if (mounted) setState(() => _permission = status.name);
    } on Object catch (error) {
      if (mounted) setState(() => _permission = 'Error: $error');
    }
  }

  void _start() {
    _level = '';
    _detections.clear();
    _status = 'Listening…';
    // Values arrive many times a second; the screen shows the latest ones
    // at a readable pace.
    _refresh = Timer.periodic(kRefreshInterval, (_) => setState(() {}));
    _subscription = widget.earshot.listen().listen(
      _onEvent,
      onError: (Object error) {
        _status = '$error';
        unawaited(_stop());
      },
      onDone: () => unawaited(_stop()),
    );
    setState(() {});
  }

  void _onEvent(EarshotEvent event) {
    final level = event.level;
    if (level != null) _level = _formatLevel(level);
    for (final detection in event.detections) {
      _detections.insert(0, _formatDetection(detection));
    }
    if (_detections.length > kMaxDetections) {
      _detections.removeRange(kMaxDetections, _detections.length);
    }
  }

  Future<void> _stop() async {
    _refresh?.cancel();
    _refresh = null;
    final subscription = _subscription;
    _subscription = null;
    if (_status == 'Listening…') _status = 'Stopped';
    if (mounted) setState(() {});
    await subscription?.cancel();
  }

  static String _formatLevel(LevelReading level) {
    String db(double value) => value.toStringAsFixed(1);
    return '${db(level.db)} dB(${level.weighting.name.toUpperCase()})\n'
        'Leq 1 s ${db(level.leq1s)} · Leq 60 s ${db(level.leq60s)} · '
        'Leq session ${db(level.leq)}';
  }

  static String _formatDetection(SoundDetection detection) {
    final seconds = (detection.timestamp.inMilliseconds / 1000).toStringAsFixed(
      1,
    );
    final name = detection.sound?.displayName ?? detection.rawLabel;
    final confidence = detection.confidence.toStringAsFixed(2);
    return '$seconds s  $name (${detection.group.name}) '
        '$confidence · ${detection.backend.name}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('earshot $kEarshotVersion')),
      // A Column, not a ListView: a lazy list would rebuild or dispose the
      // capture demo as detections are added or it scrolls off screen,
      // which stops its capture.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Microphone permission', style: textTheme.titleMedium),
            Text(_permission, key: const Key('permission')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _listening ? _stop : _start,
              child: Text(_listening ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 16),
            Text(_status, key: const Key('status')),
            const SizedBox(height: 8),
            Text(_level, key: const Key('level'), style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Recent detections', style: textTheme.titleMedium),
            Text(
              'earshot is informational and is not a certified detector.',
              style: textTheme.bodySmall,
            ),
            for (final (index, detection) in _detections.indexed)
              Text(detection, key: Key('detection$index')),
            const SizedBox(height: 24),
            CaptureDemo(
              microphonePermission: widget.microphonePermission,
              onPermissionChanged: (status) =>
                  setState(() => _permission = status.name),
            ),
          ],
        ),
      ),
    );
  }
}
