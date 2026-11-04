# earshot_classifier_darwin

[![pub package](https://img.shields.io/pub/v/earshot_classifier_darwin.svg)](https://pub.dev/packages/earshot_classifier_darwin)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.x).** The public API may still change in 0.x. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

The iOS and macOS implementation of [`earshot_classifier`](https://pub.dev/packages/earshot_classifier), backed by Apple's on-device SoundAnalysis (iOS 15+, macOS 12+). It is endorsed, so apps should depend on `earshot_classifier` and get this package automatically.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## How it works

- Each `listen()` on `detections()` starts its own session, with its own `SNAudioStreamAnalyzer` and `SNClassifySoundRequest` (classifier version 1). Sessions that run at the same time share one `AVAudioEngine` input tap, and the microphone is released when the last one is cancelled.
- Every label of an analysis window (about one second, overlapping by half) at or above the minimum confidence is reported. Labels are mapped to `EarshotSound` and `SoundGroup` in Dart, with `SoundVocabulary`.
- `isAvailable()` never prompts, and neither does classification: request the microphone permission first, for example with `EarshotCapture.requestMicrophonePermission()`. Without it, the stream fails with `CaptureException(CaptureErrorCode.permissionDenied)`.
- On iOS the audio session uses the `.record` category and the `.measurement` mode. Interruptions (calls, Siri, route and device changes) pause the detections, which resume on their own afterwards.
- No audio is written to disk or leaves the device.

## Minimum OS versions

Sound classification on Apple platforms uses SoundAnalysis, so apps that depend on this package need iOS 15 or macOS 12 or later.

## Microphone setup

Your app declares microphone access, not this package: add `NSMicrophoneUsageDescription` to `Info.plist`, and on macOS also add the `com.apple.security.device.audio-input` entitlement.

## Disclaimer

earshot is informational and is not a certified detector. Never rely on it for safety, including smoke and carbon monoxide alarms.
