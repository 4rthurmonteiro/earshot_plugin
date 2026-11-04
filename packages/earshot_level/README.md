# earshot_level

[![pub package](https://img.shields.io/pub/v/earshot_level.svg)](https://pub.dev/packages/earshot_level)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.0.1, API preview).** The public types are final for review, but most calls are not implemented yet and complete with an `UnimplementedError`. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

Pure Dart sound level metering: A, C and Z weighting, Fast, Slow and Impulse response, Leq and device calibration. Feed it the PCM from [`earshot_capture`](https://pub.dev/packages/earshot_capture).

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.
