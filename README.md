# earshot

[![ci](https://github.com/4rthurmonteiro/earshot_plugin/actions/workflows/ci.yaml/badge.svg)](https://github.com/4rthurmonteiro/earshot_plugin/actions/workflows/ci.yaml)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.1.0).** Capture, level metering and sound classification work on Android, iOS and macOS. The public API may still change before 1.0.0. The [feature checklist](#feature-checklist) shows what works today.

On-device ambient listening for Flutter. earshot tells your app **how loud it is**, in dB(A) with Leq and calibration, and **what is sounding**, through sound classification. It has the same API on Android, iOS and macOS.

## Privacy

- earshot never uses the network and sends no telemetry.
- Audio never leaves the device and is never written to disk.
- Reading the microphone permission status never prompts the user.
- The Apple packages ship a privacy manifest that declares no data collection and no tracking.

Your app owns the microphone usage declarations: `NSMicrophoneUsageDescription` in the iOS and macOS `Info.plist`, plus the `com.apple.security.device.audio-input` entitlement on macOS. Android's `RECORD_AUDIO` is merged into your manifest, and your app still asks the user at runtime.

## Disclaimer

earshot is informational and is not a certified detector. Never rely on it for safety. In particular, it must not replace a certified smoke or carbon monoxide alarm.

## Packages

Most apps need only `earshot_plugin`, or `earshot_level` if they just want a sound level meter.

| Package | What it does | pub.dev |
| --- | --- | --- |
| [`earshot_plugin`](packages/earshot_plugin) | Level and classification in one stream | [![pub](https://img.shields.io/pub/v/earshot_plugin.svg)](https://pub.dev/packages/earshot_plugin) |
| [`earshot_capture`](packages/earshot_capture/earshot_capture) | Microphone → float32 PCM, permission status | [![pub](https://img.shields.io/pub/v/earshot_capture.svg)](https://pub.dev/packages/earshot_capture) |
| [`earshot_level`](packages/earshot_level) | Pure Dart dB metering: weighting, Leq, calibration | [![pub](https://img.shields.io/pub/v/earshot_level.svg)](https://pub.dev/packages/earshot_level) |
| [`earshot_classifier`](packages/earshot_classifier/earshot_classifier) | Sound classification (SoundAnalysis, YAMNet) | [![pub](https://img.shields.io/pub/v/earshot_classifier.svg)](https://pub.dev/packages/earshot_classifier) |
| [`earshot_capture_platform_interface`](packages/earshot_capture/earshot_capture_platform_interface) | Capture platform interface | [![pub](https://img.shields.io/pub/v/earshot_capture_platform_interface.svg)](https://pub.dev/packages/earshot_capture_platform_interface) |
| [`earshot_capture_android`](packages/earshot_capture/earshot_capture_android) | Capture on Android | [![pub](https://img.shields.io/pub/v/earshot_capture_android.svg)](https://pub.dev/packages/earshot_capture_android) |
| [`earshot_capture_darwin`](packages/earshot_capture/earshot_capture_darwin) | Capture on iOS and macOS | [![pub](https://img.shields.io/pub/v/earshot_capture_darwin.svg)](https://pub.dev/packages/earshot_capture_darwin) |
| [`earshot_classifier_platform_interface`](packages/earshot_classifier/earshot_classifier_platform_interface) | Classifier platform interface | [![pub](https://img.shields.io/pub/v/earshot_classifier_platform_interface.svg)](https://pub.dev/packages/earshot_classifier_platform_interface) |
| [`earshot_classifier_darwin`](packages/earshot_classifier/earshot_classifier_darwin) | SoundAnalysis on iOS and macOS | [![pub](https://img.shields.io/pub/v/earshot_classifier_darwin.svg)](https://pub.dev/packages/earshot_classifier_darwin) |

## Feature checklist

An item is ticked (`- [x]`) in the same pull request that implements it. The version that first ships it is appended on release, for example `(0.1.0)`.

### 0.0.1: foundation

**Workspace**
- [x] Melos 8 on Dart pub workspaces, with one lockfile (0.0.1)
- [x] CI: analyze, format, 100% test coverage, generated-code check, Android example build (0.0.1)
- [x] Swift Package Manager and CocoaPods support for the Apple packages (0.0.1)

**earshot_capture**
- [x] Microphone permission status (Android, iOS, macOS) (0.0.1)

### 0.1.0: capture, level and classification

**earshot_capture**
- [x] Microphone permission request (0.1.0)
- [x] PCM float32 mono stream at 16 / 44.1 / 48 kHz (Android, iOS, macOS) (0.1.0)
- [x] Capture state changes (0.1.0)
- [ ] Interruption handling (calls, Siri, Android input silencing) with auto-resume, without taking audio focus
- [x] Unprocessed input (iOS `.measurement` mode, Android `UNPROCESSED` with `VOICE_RECOGNITION` fallback) (0.1.0)

**earshot_level**
- [x] A and Z weighting (IEC 61672, ±0.5 dB at 10 frequencies) (0.1.0)
- [x] C weighting (0.1.0)
- [x] Fast / Slow / Impulse response (0.1.0)
- [x] Leq (session, 1 s, 60 s) (0.1.0)
- [x] Calibration offset (0.1.0)

**earshot_classifier**
- [x] YAMNet backend via LiteRT, in an isolate (every platform) (0.1.0)
- [x] Apple SoundAnalysis backend (iOS 15+, macOS 12+) (0.1.0)
- [x] Backend selection (`auto`, `apple`, `yamnet`) (0.1.0)
- [x] Sound vocabulary (`EarshotSound`) with validated label mapping (0.1.0)
- [x] Confidence threshold and smoothing (N hits within T seconds) (0.1.0)

**earshot_plugin**
- [x] `Earshot.listen` combining level and classification (0.1.0)
- [x] `EarshotException` error codes on stream errors (0.1.0)

### 0.2.0: consolidation

- [ ] SoundAnalysis fed from the shared capture tap (single microphone session)
- [ ] Release automation with `melos version` and Conventional Commits
- [ ] pana checks in CI

### 1.0.0: stable

- [ ] Stable public API
- [ ] Performance measured on real devices (YAMNet under 50 ms per window on a mid-range Android device)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Architecture decisions are recorded in [`docs/adr/`](docs/adr/README.md).

## License

[MIT](LICENSE)
