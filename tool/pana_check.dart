// Scores the package in the current directory with pana, as pub.dev would,
// and exits with an error unless it gets every point.
//
// pana resolves dependencies from pub.dev, never from the workspace. A
// package that needs a sibling version that is not published yet cannot be
// scored until the release, so it is skipped with a warning instead.
//
// Run it through melos from the workspace root: `dart run melos run pana`.
import 'dart:convert';
import 'dart:io';

/// The pub error when a constraint names a version that is not published.
final _unreleasedSibling = RegExp(
  r"depends on (earshot_\w+) (\S+) which doesn't match any versions",
);

Future<void> main() async {
  final package = Directory.current.path;
  final root = Platform.environment['MELOS_ROOT_PATH'] ?? package;
  final name = package.split(Platform.pathSeparator).last;

  // `dart` runs from <flutter>/bin/cache/dart-sdk/bin/dart.
  final flutterSdk = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;

  final result = await Process.run('pana', [
    '--json',
    '--no-warning',
    '--flutter-sdk',
    flutterSdk,
    '--project-root',
    root,
    package,
  ]);
  final Map<String, Object?> report;
  try {
    report = jsonDecode(result.stdout as String) as Map<String, Object?>;
  } on FormatException {
    stderr
      ..writeln('pana did not produce a report for $name.')
      ..writeln(result.stderr);
    exit(1);
  }

  final scores = report['scores']! as Map<String, Object?>;
  final granted = scores['grantedPoints']! as int;
  final max = scores['maxPoints']! as int;

  if (granted == max) {
    stdout.writeln('$name: $granted / $max');
    return;
  }

  final unreleased = _unreleasedSibling.firstMatch(jsonEncode(report));
  if (unreleased != null) {
    _warn(
      '$name: skipped, it needs ${unreleased[1]} ${unreleased[2]}, which is '
      'not on pub.dev yet. It is scored once that version is published.',
    );
    return;
  }

  stderr.writeln('$name: $granted / $max');
  final sections =
      (report['report']! as Map<String, Object?>)['sections']! as List<Object?>;
  for (final section in sections.cast<Map<String, Object?>>()) {
    if (section['grantedPoints'] == section['maxPoints']) continue;
    stderr
      ..writeln()
      ..writeln(
        '${section['title']} '
        '(${section['grantedPoints']} / ${section['maxPoints']})',
      )
      ..writeln(section['summary']);
  }
  exit(1);
}

void _warn(String message) {
  if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
    stdout.writeln('::warning::$message');
  } else {
    stdout.writeln('Warning: $message');
  }
}
