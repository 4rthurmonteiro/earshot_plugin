import 'dart:async';
import 'dart:typed_data';

import 'package:earshot_example/capture_demo.dart';
import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshotCapture extends Mock implements EarshotCapture;

class _MockMicrophonePermission extends Mock implements MicrophonePermission;

PcmChunk _chunk(List<double> samples) => PcmChunk(
  samples: Float32List.fromList(samples),
  sampleRate: SampleRate.hz16000,
  timestamp: Duration.zero,
);

void main() {
  late EarshotCapture capture;
  late MicrophonePermission permission;
  late StreamController<PcmChunk> pcm;
  late StreamController<CaptureState> states;

  setUp(() {
    capture = _MockEarshotCapture();
    permission = _MockMicrophonePermission();
    pcm = StreamController();
    states = StreamController();
    when(capture.pcm).thenAnswer((_) => pcm.stream);
    when(capture.stateChanges).thenAnswer((_) => states.stream);
  });

  Widget buildDemo() => MaterialApp(
    home: Scaffold(
      body: CaptureDemo(capture: capture, microphonePermission: permission),
    ),
  );

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('shows the requested permission', (tester) async {
    when(permission.request)
        .thenAnswer((_) async => MicrophonePermissionStatus.granted);

    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Request permission'));
    await tester.pump();

    expect(textOf(tester, 'capturePermission'), 'granted');
  });

  testWidgets('shows a permission request error', (tester) async {
    when(permission.request).thenAnswer((_) async => throw StateError('boom'));

    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Request permission'));
    await tester.pump();

    expect(textOf(tester, 'capturePermission'), 'Error: Bad state: boom');
  });

  testWidgets('shows the state and the level, then stops', (tester) async {
    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Start capture'));
    await tester.pump();

    states
      ..add(CaptureState.capturing)
      ..addError(StateError('ignored'));
    pcm
      ..add(_chunk([0.5, -0.5]))
      ..add(_chunk([]));
    await tester.pump(kRefreshInterval);

    expect(textOf(tester, 'captureState'), 'capturing');
    expect(textOf(tester, 'capturePcm'), '2 chunks, -Infinity dBFS');

    await tester.tap(find.text('Stop capture'));
    await tester.pump();
    expect(find.text('Start capture'), findsOneWidget);
    expect(pcm.hasListener, isFalse);
    expect(states.hasListener, isFalse);
  });

  testWidgets('shows the level of a chunk', (tester) async {
    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Start capture'));
    pcm.add(_chunk([0.5, -0.5]));
    await tester.pump(kRefreshInterval);

    expect(textOf(tester, 'capturePcm'), '1 chunks, -6.0 dBFS');
  });

  testWidgets('shows a capture error and stops when the stream ends', (
    tester,
  ) async {
    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Start capture'));
    pcm.addError(const CaptureException(CaptureErrorCode.permissionDenied));
    await pcm.close();
    await tester.pump();

    expect(
      textOf(tester, 'capturePcm'),
      'Error: CaptureException(permissionDenied)',
    );
    expect(find.text('Start capture'), findsOneWidget);
  });

  testWidgets('stops capture when disposed', (tester) async {
    await tester.pumpWidget(buildDemo());
    await tester.tap(find.text('Start capture'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    expect(pcm.hasListener, isFalse);
  });
}
