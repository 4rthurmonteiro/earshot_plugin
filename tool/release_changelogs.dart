// Gives every package that `melos version` bumped a CHANGELOG.md section for
// its new version. It runs as the `preCommit` hook of `melos version`.
//
// Changelog entries are written by hand under `## Unreleased`. That heading
// becomes the new version. A package bumped only because a dependency
// changed has no such section, so it gets a short one.
import 'dart:io';

final _version = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);
final _heading = RegExp(r'^## (.+)$', multiLine: true);

void main() {
  final root =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;
  final rootPubspec = File('$root/pubspec.yaml').readAsStringSync();
  final members = RegExp(r'^  - (\S+)$', multiLine: true)
      .allMatches(
        rootPubspec.substring(
          rootPubspec.indexOf('workspace:'),
          rootPubspec.indexOf('\n\n', rootPubspec.indexOf('workspace:')),
        ),
      )
      .map((match) => match[1]!);

  for (final member in members) {
    final pubspec = File('$root/$member/pubspec.yaml').readAsStringSync();
    final changelog = File('$root/$member/CHANGELOG.md');
    if (pubspec.contains(RegExp(r'^publish_to:\s*none', multiLine: true)) ||
        !changelog.existsSync()) {
      continue;
    }
    final version = _version.firstMatch(pubspec)![1]!;
    final text = changelog.readAsStringSync();
    final headings = _heading.allMatches(text).toList();
    // Not bumped by this run: its version is already in the changelog.
    if (headings.any((heading) => heading[1] == version)) continue;

    final heading = headings.firstOrNull;

    final String updated;
    if (heading?[1] == 'Unreleased') {
      updated = text.replaceRange(heading!.start, heading.end, '## $version');
    } else {
      final insertAt = heading?.start ?? text.length;
      updated = text.replaceRange(
        insertAt,
        insertAt,
        '## $version\n\n- Update dependencies.\n\n',
      );
    }
    changelog.writeAsStringSync(updated);
    stdout.writeln('$member: CHANGELOG.md now starts at $version.');
  }
}
