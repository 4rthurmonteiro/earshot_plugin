import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/apple_labels.dart';
import 'package:earshot_classifier_platform_interface/src/vocabulary/yamnet_labels.dart';
import 'package:test/test.dart';

import 'vocabulary_validator.dart';

void main() {
  group('vocabulary validation', () {
    final official = readOfficialLabels();

    test('reads the official label lists', () {
      expect(official.yamnet, hasLength(521));
      expect(official.yamnet.first, 'Speech');
      expect(official.yamnet.last, 'Field recording');
      expect(official.apple, hasLength(303));
      expect(official.apple, contains('smoke_detector'));
    });

    test('maps every label of EarshotSound to an official label', () {
      final problems = validateVocabulary(
        sounds: [
          for (final sound in EarshotSound.values)
            (
              name: sound.name,
              group: sound.group,
              apple: sound.appleLabels,
              yamnet: sound.yamnetLabels,
            ),
        ],
        officialApple: official.apple,
        officialYamnet: official.yamnet,
        appleGroups: appleLabelGroups,
        yamnetGroups: yamnetLabelGroups,
      );
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    group('validator', () {
      const officialApple = ['dog_bark', 'cat'];
      const officialYamnet = ['Bark', 'Cat'];
      const appleGroups = {
        'dog_bark': SoundGroup.animals,
        'cat': SoundGroup.animals,
      };
      const yamnetGroups = {
        'Bark': SoundGroup.animals,
        'Cat': SoundGroup.animals,
      };

      List<String> validate(
        List<VocabularyEntry> sounds, {
        Map<String, SoundGroup?> apple = appleGroups,
        Map<String, SoundGroup?> yamnet = yamnetGroups,
      }) => validateVocabulary(
        sounds: sounds,
        officialApple: officialApple,
        officialYamnet: officialYamnet,
        appleGroups: apple,
        yamnetGroups: yamnet,
      );

      test('accepts a valid vocabulary', () {
        expect(
          validate([
            (
              name: 'dogBark',
              group: SoundGroup.animals,
              apple: ['dog_bark'],
              yamnet: ['Bark'],
            ),
            (
              name: 'cat',
              group: SoundGroup.animals,
              apple: [],
              yamnet: ['Cat'],
            ),
          ]),
          isEmpty,
        );
      });

      test('reports a sound with no backend', () {
        expect(
          validate([
            (name: 'unicorn', group: SoundGroup.animals, apple: [], yamnet: []),
          ]),
          ['unicorn: maps to no backend label'],
        );
      });

      test('reports a label missing from its backend', () {
        expect(
          validate([
            (
              name: 'dogBark',
              group: SoundGroup.animals,
              apple: ['dog_woof'],
              yamnet: ['Woof'],
            ),
          ]),
          [
            'dogBark: apple label "dog_woof" does not exist',
            'dogBark: yamnet label "Woof" does not exist',
          ],
        );
      });

      test('reports a label mapped twice', () {
        expect(
          validate([
            (
              name: 'dogBark',
              group: SoundGroup.animals,
              apple: ['dog_bark'],
              yamnet: [],
            ),
            (
              name: 'dog',
              group: SoundGroup.animals,
              apple: ['dog_bark'],
              yamnet: [],
            ),
          ]),
          ['dog: apple label "dog_bark" is already mapped by dogBark'],
        );
      });

      test('reports a label whose group differs from its sound', () {
        expect(
          validate([
            (
              name: 'dogBark',
              group: SoundGroup.home,
              apple: [],
              yamnet: ['Bark'],
            ),
          ]),
          [contains('"Bark" falls back to SoundGroup.animals, not SoundGroup')],
        );
      });

      test('reports a group table that differs from the official list', () {
        expect(
          validate(
            [],
            apple: {'cat': SoundGroup.animals, 'dog_bark': SoundGroup.animals},
            yamnet: {'Bark': SoundGroup.animals},
          ),
          [
            'apple group table has "cat" at 0, expected "dog_bark"',
            'apple group table has "dog_bark" at 1, expected "cat"',
            'yamnet group table has 1 labels, expected 2',
          ],
        );
      });
    });

    group('parseCsv', () {
      test('handles quoted fields, escaped quotes and CRLF', () {
        expect(parseCsv('a,"b, c"\r\n"d ""e""",f'), [
          ['a', 'b, c'],
          ['d "e"', 'f'],
        ]);
      });
    });
  });
}
