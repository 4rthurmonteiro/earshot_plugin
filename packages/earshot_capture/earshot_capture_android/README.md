# earshot_capture_android

[![pub package](https://img.shields.io/pub/v/earshot_capture_android.svg)](https://pub.dev/packages/earshot_capture_android)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

The Android implementation of [`earshot_capture`](https://pub.dev/packages/earshot_capture). It is endorsed, so apps should depend on `earshot_capture` and get this package automatically.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Microphone setup

Your app declares microphone access, not this package:

- **iOS and macOS:** add `NSMicrophoneUsageDescription` to `Info.plist`. On macOS, also add the `com.apple.security.device.audio-input` entitlement.
- **Android:** `RECORD_AUDIO` is merged into your app's manifest by `earshot_capture_android`. Your app still asks the user at runtime.
