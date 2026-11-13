# earshot_classifier

[![pub package](https://img.shields.io/pub/v/earshot_classifier.svg)](https://pub.dev/packages/earshot_classifier)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.x).** The public API may still change in 0.x. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

On-device sound classification for Flutter. It uses Apple SoundAnalysis on iOS and macOS and Google YAMNet (via LiteRT) everywhere else, and maps both to the same `EarshotSound` vocabulary and sound groups.

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Usage

```dart
import 'package:earshot_classifier/earshot_classifier.dart';

final subscription = const EarshotClassifier(
  options: ClassifierOptions(
    minConfidence: 0.5,
    smoothing: Smoothing(hits: 2, window: Duration(seconds: 2)),
  ),
).detections().listen((detection) {
  // sound is null when the label maps to no EarshotSound.
  print('${detection.group} ${detection.sound} ${detection.rawLabel}');
});

// Cancelling stops classification and releases the microphone.
await subscription.cancel();
```

To share one capture stream with other consumers, such as a level meter, classify PCM you already have with `classify(pcm)`. It picks the backend the same way. SoundAnalysis accepts every capture rate, and YAMNet resamples 44.1 or 48 kHz PCM to 16 kHz.

## Backends

| `ClassifierOptions.backend` | Engine | Platforms |
| --- | --- | --- |
| `null` (default) | `apple` on iOS and macOS when it is available, `yamnet` otherwise | all |
| `apple` | Apple SoundAnalysis, on PCM from `earshot_capture` | iOS 15+, macOS 12+ |
| `yamnet` | YAMNet float32 with LiteRT, in a background isolate | Android, iOS, macOS |

Confidence scores from different backends cannot be compared. Pick `yamnet` on every platform for consistent results.

YAMNet classifies 0.975 s windows with a 50% hop, so it reports about twice per second. The ~4 MB model is bundled with this package and never downloaded.

## Vocabulary

`EarshotSound` lists the sounds earshot recognizes, with the same identifier on every backend, for example `dogBark`, `babyCrying`, `doorbell`, `smokeAlarm` or `siren`. Each sound belongs to a `SoundGroup`: people, animals, home, alarms, vehicles, tools, music, nature or other. `EarshotSound.isSupportedBy(backend)` tells whether a backend can recognize it.

A label that maps to no `EarshotSound` is still reported, with its `group` and `rawLabel` and a `null` `sound`. Neither backend has a separate carbon monoxide alarm label: a CO alarm is reported as `smokeAlarm`, `beep` or `alarm`.

The vocabulary grows: new values of `EarshotSound`, `SoundGroup` and `ClassifierBackend` may be added in a minor version. Keep a wildcard case when you switch on them:

```dart
final icon = switch (detection.group) {
  SoundGroup.alarms => '🚨',
  SoundGroup.animals => '🐶',
  _ => '🔊',
};
```

## Confidence and smoothing

Detections below `minConfidence` are dropped. A sound is reported only after `Smoothing.hits` detections within `Smoothing.window` (2 within 2 seconds by default), and then for every window in which it is still detected that often.

## Performance

The time YAMNet takes per window, measured in profile mode with the benchmark in the example app (ADR 0022). Run it on your own device from `examples/earshot_example`:

```sh
flutter drive --profile -d <device> \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/yamnet_benchmark_test.dart
```

| Device | OS | earshot | p50 | p95 | First window |
| --- | --- | --- | --- | --- | --- |
| MacBook (Apple M4) | macOS 26.5 | 0.2.0 | 1.1 ms | 1.2 ms | 10 ms |

The target is a p95 under 50 ms on a mid-range Android device. The first window includes loading the model.

## Minimum OS versions

Sound classification on Apple platforms uses SoundAnalysis, so apps that depend on this package need iOS 15 or macOS 12 or later.

## Disclaimer

earshot is informational and is not a certified detector. Never rely on it for safety, including smoke and carbon monoxide alarms.

## License

MIT. The bundled YAMNet model and class map are Apache-2.0: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
