import 'package:earshot_example/app.dart';
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

  testWidgets('shows the 0.0.1 error when Start is tapped', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(textOf(tester, 'status'), startsWith('UnimplementedError'));
  });

  testWidgets('shows events as they arrive', (tester) async {
    final earshot = _MockEarshot();
    const event = EarshotEvent(timestamp: Duration(seconds: 1));
    when(earshot.listen).thenAnswer((_) => Stream.value(event));

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(textOf(tester, 'status'), event.toString());
  });

  testWidgets('restarts listening on a second tap', (tester) async {
    final earshot = _MockEarshot();
    when(earshot.listen).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(buildPage(earshot: earshot));
    await tester.tap(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();

    verify(earshot.listen).called(2);
  });
}
