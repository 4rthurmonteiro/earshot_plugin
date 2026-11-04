# earshot_classifier_darwin

[![pub package](https://img.shields.io/pub/v/earshot_classifier_darwin.svg)](https://pub.dev/packages/earshot_classifier_darwin)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.0.1, API preview).** The public types are final for review, but most calls are not implemented yet and complete with an `UnimplementedError`. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

The iOS and macOS implementation of [`earshot_classifier`](https://pub.dev/packages/earshot_classifier), backed by Apple's on-device SoundAnalysis (iOS 15+, macOS 12+). It is endorsed, so apps should depend on `earshot_classifier` and get this package automatically.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Disclaimer

earshot is informational and is not a certified detector. Never rely on it for safety, including smoke and carbon monoxide alarms.
