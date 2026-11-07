# earshot_classifier_platform_interface

[![pub package](https://img.shields.io/pub/v/earshot_classifier_platform_interface.svg)](https://pub.dev/packages/earshot_classifier_platform_interface)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.x).** The public API may still change in 0.x. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

The pure Dart platform interface for [`earshot_classifier`](https://pub.dev/packages/earshot_classifier). Apps should depend on `earshot_classifier` instead.

It holds the types every backend shares: `SoundDetection`, `SoundGroup`, `ClassifierBackend`, the `EarshotSound` vocabulary and `SoundVocabulary`, which maps each backend's raw labels to sounds and groups.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Implementing a backend

A platform implementation extends `EarshotClassifierPlatform` and runs its own microphone session:

- `isAvailable()` tells whether the backend can run on this device. It must never prompt the user.
- `detections(ClassifierConfig config)` starts a session on each `listen()` and stops it on cancel. It reports every label at or above `config.minConfidence` in each analysis window, built with `SoundVocabulary().detection(...)`, and never throws synchronously.

`earshot_classifier` applies the confidence threshold and smoothing on top, the same way for every backend. See [ADR 0014](https://github.com/4rthurmonteiro/earshot_plugin/blob/main/docs/adr/0014-classifier-platform-interface-and-model-bundling.md).

## Disclaimer

earshot is informational and is not a certified detector. Never rely on it for safety, including smoke and carbon monoxide alarms.
