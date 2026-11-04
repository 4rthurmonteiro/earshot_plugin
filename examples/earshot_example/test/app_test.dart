import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_example/app.dart';
import 'package:earshot_plugin/earshot_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockEarshot extends Mock implements Earshot;

class _MockEarshotCapturePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EarshotCapturePlatform;

void main() {
  late EarshotCapturePlatform platform;

  setUp(() {
    platform = _MockEarshotCapturePlatform();
    EarshotCapturePlatform.instance = platform;
  });

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('shows the microphone permission status', (tester) async {
    when(platform.microphonePermissionStatus)
        .thenAnswer((_) async => MicrophonePermissionStatus.granted);

    await tester.pumpWidget(const EarshotExampleApp());
    await tester.pump();

    expect(textOf(tester, 'permission'), 'granted');
  });

  testWidgets('shows an error when the status cannot be read', (tester) async {
    when(platform.microphonePermissionStatus)
        .thenAnswer((_) async => throw StateError('boom'));

    await tester.pumpWidget(const EarshotExampleApp());
    await tester.pump();

    expect(textOf(tester, 'permission'), 'Error: Bad state: boom');
  });

  testWidgets('shows the 0.0.1 error when Start is tapped', (tester) async {
    when(platform.microphonePermissionStatus)
        .thenAnswer((_) async => MicrophonePermissionStatus.denied);

    await tester.pumpWidget(const EarshotExampleApp());
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(textOf(tester, 'status'), startsWith('UnimplementedError'));
  });

  testWidgets('shows events and restarts on a second tap', (tester) async {
    final earshot = _MockEarshot();
    const event = EarshotEvent(timestamp: Duration(seconds: 1));
    when(platform.microphonePermissionStatus)
        .thenAnswer((_) async => MicrophonePermissionStatus.granted);
    when(earshot.listen).thenAnswer((_) => Stream.value(event));

    await tester.pumpWidget(MaterialApp(home: EarshotPage(earshot: earshot)));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(textOf(tester, 'status'), event.toString());

    await tester.tap(find.text('Start'));
    await tester.pump();
    verify(earshot.listen).called(2);
  });
}
