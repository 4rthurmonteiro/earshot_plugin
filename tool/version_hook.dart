// The `preCommit` hook of `melos version` (ADR 0020). After melos bumps the
// pubspecs, it brings the files melos doesn't know about to the new
// versions:
//
// - CHANGELOG.md: entries are written by hand under `## Unreleased`, and
//   that heading becomes the new version. A package bumped only because a
//   dependency changed has no such section, so it gets a short one.
// - Podspecs: `s.version` in every `darwin/*.podspec` follows the pubspec.
// - The example: `kEarshotVersion` follows `earshot_plugin`.
//
// melos stages the pubspecs and changelogs; this hook stages the rest.
import 'dart:io';

final _version = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);
final _name = RegExp(r'^name:\s*(\S+)\s*$', multiLine: true);
final _heading = RegExp(r'^## (.+)$', multiLine: true);
final _podspecVersion = RegExp(
  r"^(\s*s\.version\s*=\s*)'[^']*'",
  multiLine: true,
);
final _exampleVersion = RegExp(
  "^const kEarshotVersion = '[^']*';",
  multiLine: true,
);

void main() {
  final root =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;
  final rootPubspec = File('$root/pubspec.yaml').readAsStringSync();
  final start = rootPubspec.indexOf('workspace:');
  final members = RegExp(r'^  - (\S+)$', multiLine: true)
      .allMatches(
        rootPubspec.substring(start, rootPubspec.indexOf('\n\n', start)),
      )
      .map((match) => match[1]!);

  for (final member in members) {
    final dir = '$root/$member';
    final pubspec = File('$dir/pubspec.yaml').readAsStringSync();
    if (pubspec.contains(RegExp(r'^publish_to:\s*none', multiLine: true))) {
      continue;
    }
    final version = _version.firstMatch(pubspec)![1]!;
    _updateChangelog(member, File('$dir/CHANGELOG.md'), version);
    final darwin = Directory('$dir/darwin');
    if (darwin.existsSync()) {
      for (final podspec in darwin.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.podspec'),
      )) {
        _replace(podspec, _podspecVersion, (match) => "${match[1]}'$version'");
      }
    }
    if (_name.firstMatch(pubspec)![1] == 'earshot_plugin') {
      _replace(
        File('$root/examples/earshot_example/lib/app.dart'),
        _exampleVersion,
        (_) => "const kEarshotVersion = '$version';",
      );
    }
  }
}

void _updateChangelog(String member, File changelog, String version) {
  if (!changelog.existsSync()) return;
  final text = changelog.readAsStringSync();
  final headings = _heading.allMatches(text).toList();
  // Not bumped by this run: its version is already in the changelog.
  if (headings.any((heading) => heading[1] == version)) return;

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

void _replace(File file, RegExp pattern, String Function(Match) replace) {
  final text = file.readAsStringSync();
  final updated = text.replaceFirstMapped(pattern, replace);
  if (updated == text) return;
  file.writeAsStringSync(updated);
  // melos stages only pubspecs and changelogs.
  final added = Process.runSync('git', ['add', file.path]);
  if (added.exitCode != 0) {
    stderr.write(added.stderr);
    exit(1);
  }
  stdout.writeln('${file.path}: version updated.');
}
