# tools/vocab

The official label lists of each classifier backend, and the validator that checks `EarshotSound` against them ([ADR 0011](../../docs/adr/0011-sound-vocabulary.md), [ADR 0014](../../docs/adr/0014-classifier-platform-interface-and-model-bundling.md)).

| File | What it is |
| --- | --- |
| `yamnet_class_map.csv` | The 521 YAMNet classes in model output order, from [tensorflow/models](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/yamnet_class_map.csv) (Apache-2.0). |
| `apple_labels.txt` | The 303 labels of Apple's built-in SoundAnalysis classifier (version 1), one per line. |
| `apple_labels.swift` | Regenerates `apple_labels.txt` on a Mac with macOS 12 or later. |

## The vocabulary data

The vocabulary lives in `packages/earshot_classifier/earshot_classifier_platform_interface/lib/src/vocabulary/`:

- `earshot_sound.dart`: each `EarshotSound` with its group, display name, and the Apple and YAMNet labels it maps to.
- `yamnet_labels.dart` and `apple_labels.dart`: every label of each backend with the group it falls back to when it maps to no sound. A `null` group means the label is never reported (silence).

## Validation

The validator is `test/src/vocabulary/vocabulary_validator.dart` in `earshot_classifier_platform_interface`, and `vocabulary_validation_test.dart` runs it against the files here as part of `dart run melos run test`. The test fails if:

- a sound maps to no label of any backend,
- a mapped label does not exist in its backend's list,
- a label maps to two sounds,
- a group table does not list exactly the official labels (YAMNet in model output order), or
- a mapped label falls back to a group other than its sound's.

The validator lives in the package's tests rather than in a separate `tools/` package, so it needs no extra workspace member and runs with the existing test and coverage setup.

## Updating

```bash
# Apple: run on a Mac.
swift tools/vocab/apple_labels.swift > tools/vocab/apple_labels.txt

# YAMNet: only from the official tensorflow/models repository.
curl -L -o tools/vocab/yamnet_class_map.csv \
  https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv
```

Then run the platform interface tests and fix every reported problem in the vocabulary data. Renaming an `EarshotSound` value is a breaking change.
