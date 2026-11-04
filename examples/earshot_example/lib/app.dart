import 'dart:async';

import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';

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

/// Shows the microphone permission status and starts listening.
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
  StreamSubscription<EarshotEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    unawaited(_readPermission());
  }

  @override
  void dispose() {
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
    unawaited(_subscription?.cancel());
    setState(() => _status = 'Listening…');
    _subscription = widget.earshot.listen().listen(
      (event) => setState(() => _status = '$event'),
      onError: (Object error) => setState(() => _status = '$error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('earshot 0.0.1')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Microphone permission', style: textTheme.titleMedium),
          Text(_permission, key: const Key('permission')),
          const SizedBox(height: 24),
          FilledButton(onPressed: _start, child: const Text('Start')),
          const SizedBox(height: 16),
          Text(_status, key: const Key('status')),
        ],
      ),
    );
  }
}
