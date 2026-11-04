# earshot_capture

[![pub package](https://img.shields.io/pub/v/earshot_capture.svg)](https://pub.dev/packages/earshot_capture)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.0.1, API preview).** The public types are published for review and may still change in 0.x. Most calls are not implemented yet and complete with an `UnimplementedError`. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

On-device microphone capture for Flutter on Android, iOS and macOS: a float32 mono PCM stream at 16, 44.1 or 48 kHz, plus the microphone permission status.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Microphone setup

Your app declares microphone access, not this package:

- **iOS and macOS:** add `NSMicrophoneUsageDescription` to `Info.plist`. On macOS, also add the `com.apple.security.device.audio-input` entitlement.
- **Android:** `RECORD_AUDIO` is merged into your app's manifest by `earshot_capture_android`. Your app still asks the user at runtime.

## Usage

```dart
import 'package:earshot_capture/earshot_capture.dart';

final status = await const MicrophonePermission().request();
if (status != MicrophonePermissionStatus.granted) return;

final subscription = const EarshotCapture()
    .pcm(config: const CaptureConfig(sampleRate: SampleRate.hz48000))
    .listen(
      (chunk) => debugPrint('${chunk.samples.length} samples'),
      onError: (Object error) => debugPrint('$error'), // a CaptureException
    );

// Cancelling the last subscription closes the microphone.
await subscription.cancel();
```

- Concurrent subscriptions share one microphone session and must use the same sample rate.
- `stateChanges()` reports `interrupted` during phone calls, Siri or input device changes. Capture resumes on its own.
- The input is unprocessed where the platform allows it: the iOS `.measurement` mode, and Android's `UNPROCESSED` source with a `VOICE_RECOGNITION` fallback.
