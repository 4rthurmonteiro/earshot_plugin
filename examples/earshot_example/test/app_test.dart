import 'dart:async';

import 'package:earshot_example/app.dart';
import 'package:earshot_example/capture_demo.dart';
import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarshot extends Mock implements Earshot;

class _MockMicrophonePermission extends Mock implements MicrophonePermission;

void main() {
  late MicrophonePermission microphonePermission;

  setUp(() {
    microphonePermission = _MockMicrophonePermission();
    when(microphonePermission.status)
        .thenAnswer((_) async => MicrophonePermissionStatus.granted);
  });

  Widget buildPage({Earshot earshot = const Earshot()}) => MaterialApp(
    home: EarshotPage(
      earshot: earshot,
      microphonePermission: microphonePermission,
    ),
  );

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('renders the app', (tester) async {
    await tester.pumpWidget(const EarshotExampleApp());
    expect(find.byType(EarshotPage), findsOneWidget);
  });

  testWidgets('shows the microphone permission status', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(textOf(tester, 'permission'), 'granted');
  });

  testWidgets('shows an error when the status cannot be read', (tester) async {
    when(microphonePermission.status)
        .thenAnswer((_) async => throw StateError('boom'));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(textOf(tester, 'permission'), 'Error: Bad state: boom');
  });

  testWidgets('shows the version in the title', (tester) async {
    await tester.pumpWidget(buildPage());

    expect(find.text('earshot $kEarshotVersion'), findsOneWidget);
  });

  testWidgets('refreshes the status after a permission request', (
    tester,
  ) async {
    when(microphonePermission.request)
        .thenAnswer((_) async => MicrophonePermissionStatus.denied);

    await tester.pumpWidget(buildPage());
    await tester.pump();
    await tester.tap(find.text('Request permission'));
    await tester.pump();

    expect(textOf(tester, 'permission'), 'denied');
  });

  testWidgets('shows a stream error and stops', (tester) async {
    final earshot = _MockEarshot();
    const error = EarshotException(EarshotErrorCode.permissionDenied);
    when(earshot.listen).thenAnswer((_) => Stream.error(error));

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(textOf(tester, 'status'), error.toString());
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('shows the level and detections at a readable pace', (
    tester,
  ) async {
    final earshot = _MockEarshot();
    final events = StreamController<EarshotEvent>();
    when(earshot.listen).thenAnswer((_) => events.stream);

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(textOf(tester, 'status'), 'Listening…');

    events
      ..add(_event(db: 60))
      ..add(
        _event(
          db: 61.25,
          detections: [
            _detection(sound: EarshotSound.values.first),
            _detection(rawLabel: 'Unmapped'),
          ],
        ),
      )
      ..add(const EarshotEvent(timestamp: Duration(seconds: 2)));
    await tester.pump();
    // Nothing is shown until the next refresh.
    expect(textOf(tester, 'level'), isEmpty);

    await tester.pump(kRefreshInterval);
    expect(
      textOf(tester, 'level'),
      '61.3 dB(A)\nLeq 1 s 50.0 · Leq 60 s 40.0 · Leq session 45.0',
    );
    expect(
      textOf(tester, 'detection0'),
      '1.5 s  Unmapped (other) 0.80 · yamnet',
    );
    expect(
      textOf(tester, 'detection1'),
      '1.5 s  ${EarshotSound.values.first.displayName} (other) 0.80 · yamnet',
    );

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(textOf(tester, 'status'), 'Stopped');
    expect(events.hasListener, isFalse);
  });

  testWidgets('keeps only the most recent detections', (tester) async {
    // Tall enough for the whole list to be built.
    tester.view.physicalSize = const Size(1000, 20000);
    addTearDown(tester.view.reset);
    final earshot = _MockEarshot();
    when(earshot.listen).thenAnswer(
      (_) => Stream.value(
        EarshotEvent(
          timestamp: Duration.zero,
          detections: [
            for (var i = 0; i < kMaxDetections + 5; i++)
              _detection(rawLabel: 'label $i'),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.byKey(const Key('detection${kMaxDetections - 1}')), findsOne);
    expect(find.byKey(const Key('detection$kMaxDetections')), findsNothing);
    expect(textOf(tester, 'status'), 'Stopped');
  });

  testWidgets('stops listening when disposed', (tester) async {
    final earshot = _MockEarshot();
    final events = StreamController<EarshotEvent>();
    when(earshot.listen).thenAnswer((_) => events.stream);

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    expect(events.hasListener, isFalse);
  });
}

EarshotEvent _event({
  required double db,
  List<SoundDetection> detections = const [],
}) => EarshotEvent(
  timestamp: const Duration(seconds: 1),
  level: LevelReading(
    db: db,
    leq: 45,
    leq1s: 50,
    leq60s: 40,
    weighting: FrequencyWeighting.a,
    timestamp: const Duration(seconds: 1),
  ),
  detections: detections,
);

SoundDetection _detection({EarshotSound? sound, String rawLabel = 'raw'}) =>
    SoundDetection(
      group: SoundGroup.other,
      sound: sound,
      rawLabel: rawLabel,
      confidence: 0.8,
      backend: ClassifierBackend.yamnet,
      timestamp: const Duration(milliseconds: 1500),
    );
