// The last step of `dart run melos run release` (ADR 0027). After melos has
// published the packages and pushed the `<package>-v<version>` tags, this
// creates the GitHub release of the version, on the `earshot_plugin` tag.
//
// The notes list every package published at that version, with a link to
// pub.dev, followed by the section of each package's CHANGELOG.md for that
// version. Packages that kept an older version are named at the top.
//
// It needs the GitHub CLI (`gh`), signed in. If the release already exists,
// it does nothing. Pass `--dry-run` to print the notes without creating it.
import 'dart:io';

const _umbrella = 'earshot_plugin';

final _version = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);
final _name = RegExp(r'^name:\s*(\S+)\s*$', multiLine: true);

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final root =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;

  final packages = _publishablePackages(root);
  final version = packages
      .firstWhere((package) => package.name == _umbrella)
      .version;
  final tag = '$_umbrella-v$version';

  final released = packages
      .where((package) => _tagExists(root, '${package.name}-v$version'))
      .toList();
  if (!released.any((package) => package.name == _umbrella)) {
    _fail('The tag $tag does not exist. Run this after `melos publish`.');
  }
  final unchanged = packages.where((package) => !released.contains(package));

  final notes = StringBuffer()
    ..writeln(
      'earshot $version: on-device ambient listening for Flutter '
      '(Android, iOS, macOS). No network, no audio leaves the device.',
    );
  if (unchanged.isNotEmpty) {
    notes
      ..writeln()
      ..writeln(
        '${_names(unchanged.map((package) => '`${package.name}`'))} '
        "didn't change and keep their previous version.",
      );
  }
  final which = released.length == packages.length
      ? 'All ${packages.length}'
      : 'These';
  notes
    ..writeln()
    ..writeln(
      '$which packages are published on pub.dev at $version and tagged '
      '`<package>-v$version`:',
    )
    ..writeln();
  for (final package in released) {
    final url = 'https://pub.dev/packages/${package.name}/versions/$version';
    notes.writeln('- [${package.name}]($url)');
  }
  for (final package in released) {
    notes
      ..writeln()
      ..writeln('## ${package.name} $version')
      ..writeln()
      ..writeln(_changelogSection(package, version));
  }

  if (dryRun) {
    stdout
      ..writeln('Release $tag, titled "earshot $version":')
      ..writeln()
      ..write(notes);
    return;
  }

  final existing = await Process.run('gh', [
    'release',
    'view',
    tag,
  ], workingDirectory: root);
  if (existing.exitCode == 0) {
    stdout.writeln('The GitHub release $tag already exists; skipping.');
    return;
  }

  final notesFile = File('${Directory.systemTemp.path}/earshot-$tag.md')
    ..writeAsStringSync(notes.toString());
  final created = await Process.run('gh', [
    'release',
    'create',
    tag,
    '--verify-tag',
    '--title',
    'earshot $version',
    '--notes-file',
    notesFile.path,
    '--latest',
  ], workingDirectory: root);
  notesFile.deleteSync();
  if (created.exitCode != 0) {
    _fail('gh release create failed:\n${created.stderr}');
  }
  stdout.writeln('Created the GitHub release ${created.stdout}'.trim());
}

/// A publishable workspace member.
class _Package {
  new(this.name, this.version, this.dir);

  final String name;
  final String version;
  final String dir;
}

/// The publishable workspace members, `earshot_plugin` first and the rest in
/// workspace order.
List<_Package> _publishablePackages(String root) {
  final rootPubspec = File('$root/pubspec.yaml').readAsStringSync();
  final start = rootPubspec.indexOf('workspace:');
  final members = RegExp(r'^  - (\S+)$', multiLine: true)
      .allMatches(
        rootPubspec.substring(start, rootPubspec.indexOf('\n\n', start)),
      )
      .map((match) => match[1]!);
  final packages = <_Package>[];
  for (final member in members) {
    final dir = '$root/$member';
    final pubspec = File('$dir/pubspec.yaml').readAsStringSync();
    if (pubspec.contains(RegExp(r'^publish_to:\s*none', multiLine: true))) {
      continue;
    }
    packages.add(
      _Package(
        _name.firstMatch(pubspec)![1]!,
        _version.firstMatch(pubspec)![1]!,
        dir,
      ),
    );
  }
  return packages..sort(
    (a, b) => (a.name == _umbrella ? 0 : 1) - (b.name == _umbrella ? 0 : 1),
  );
}

bool _tagExists(String root, String tag) =>
    Process.runSync('git', [
      'rev-parse',
      '--quiet',
      '--verify',
      'refs/tags/$tag',
    ], workingDirectory: root).exitCode ==
    0;

/// The body of the `## <version>` section of the package's changelog.
String _changelogSection(_Package package, String version) {
  final text = File('${package.dir}/CHANGELOG.md').readAsStringSync();
  final section = RegExp(
    '^## ${RegExp.escape(version)}\\n(.*?)(?=^## |\\z)',
    multiLine: true,
    dotAll: true,
  ).firstMatch(text);
  if (section == null) {
    _fail('${package.name}/CHANGELOG.md has no "## $version" section.');
  }
  return section[1]!.trim();
}

/// Joins [names] as "a", "a and b" or "a, b and c".
String _names(Iterable<String> names) {
  final list = names.toList();
  if (list.length == 1) return list.single;
  return '${list.sublist(0, list.length - 1).join(', ')} and ${list.last}';
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
