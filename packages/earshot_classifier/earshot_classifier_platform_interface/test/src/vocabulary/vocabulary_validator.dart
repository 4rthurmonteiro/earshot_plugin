import 'dart:io';

import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// One vocabulary entry, as the validator sees it.
typedef VocabularyEntry = ({
  String name,
  SoundGroup group,
  List<String> apple,
  List<String> yamnet,
});

/// The official label lists, read from `tools/vocab/` at the repository
/// root.
///
/// Tests run from the package directory, three levels below the root.
({List<String> apple, List<String> yamnet}) readOfficialLabels({
  String root = '../../..',
}) {
  final apple = File('$root/tools/vocab/apple_labels.txt')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .toList();
  final rows = parseCsv(
    File('$root/tools/vocab/yamnet_class_map.csv').readAsStringSync(),
  );
  // Columns: index, mid, display_name. The first row is the header.
  final yamnet = [for (final row in rows.skip(1)) row[2]];
  return (apple: apple, yamnet: yamnet);
}

/// Parses RFC 4180 CSV: quoted fields may contain commas and `""`.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (quoted) {
      if (char == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (char == '"') {
        quoted = false;
      } else {
        field.write(char);
      }
    } else if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      row.add(field.toString());
      field.clear();
    } else if (char == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else if (char != '\r') {
      field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// Checks the vocabulary against the official label lists and returns one
/// message per problem. An empty list means the vocabulary is valid.
///
/// - Every sound maps to at least one backend label.
/// - Every mapped label exists in its backend's official list.
/// - No label maps to two sounds.
/// - The group tables list exactly the official labels, YAMNet in model
///   output order.
/// - A mapped label falls back to the group of its sound.
List<String> validateVocabulary({
  required List<VocabularyEntry> sounds,
  required List<String> officialApple,
  required List<String> officialYamnet,
  required Map<String, SoundGroup?> appleGroups,
  required Map<String, SoundGroup?> yamnetGroups,
}) {
  final problems = <String>[];

  void checkBackend(
    String backend,
    List<String> Function(VocabularyEntry) labelsOf,
    List<String> official,
    Map<String, SoundGroup?> groups,
  ) {
    final officialSet = official.toSet();
    final owners = <String, String>{};
    for (final sound in sounds) {
      for (final label in labelsOf(sound)) {
        if (!officialSet.contains(label)) {
          problems.add('${sound.name}: $backend label "$label" does not exist');
        }
        final owner = owners[label];
        if (owner != null) {
          problems.add(
            '${sound.name}: $backend label "$label" is already mapped by '
            '$owner',
          );
        }
        owners[label] = sound.name;
        if (groups.containsKey(label) && groups[label] != sound.group) {
          problems.add(
            '${sound.name}: $backend label "$label" falls back to '
            '${groups[label]}, not ${sound.group}',
          );
        }
      }
    }
    final tableLabels = groups.keys.toList();
    if (tableLabels.length != official.length) {
      problems.add(
        '$backend group table has ${tableLabels.length} labels, '
        'expected ${official.length}',
      );
    }
    for (var i = 0; i < tableLabels.length && i < official.length; i++) {
      if (tableLabels[i] != official[i]) {
        problems.add(
          '$backend group table has "${tableLabels[i]}" at $i, '
          'expected "${official[i]}"',
        );
      }
    }
  }

  for (final sound in sounds) {
    if (sound.apple.isEmpty && sound.yamnet.isEmpty) {
      problems.add('${sound.name}: maps to no backend label');
    }
  }
  checkBackend('apple', (s) => s.apple, officialApple, appleGroups);
  checkBackend('yamnet', (s) => s.yamnet, officialYamnet, yamnetGroups);
  return problems;
}
