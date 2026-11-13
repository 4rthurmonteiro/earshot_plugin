# earshot_level

[![pub package](https://img.shields.io/pub/v/earshot_level.svg)](https://pub.dev/packages/earshot_level)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> [!WARNING]
> **Pre-release (0.x).** The public API may still change in 0.x. See the [feature checklist](https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist) for what works today.

Pure Dart sound level metering: A, C and Z weighting, Fast, Slow and Impulse response, Leq and device calibration. Feed it the PCM from [`earshot_capture`](https://pub.dev/packages/earshot_capture).

Part of [earshot](https://github.com/4rthurmonteiro/earshot_plugin): on-device ambient listening with no network access, where no audio leaves the device.

## Usage

```dart
import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_level/earshot_level.dart';

final readings = const EarshotCapture().pcm().transform(
  const LevelMeter(
    options: LevelOptions(
      weighting: FrequencyWeighting.a,
      timeWeighting: TimeWeighting.fast,
      calibration: LevelCalibration(offsetDb: 100),
    ),
  ),
);

readings.listen((reading) {
  print('${reading.db} dB(A), Leq 1 s ${reading.leq1s}, Leq 60 s ${reading.leq60s}');
});
```

The meter emits one `LevelReading` per PCM chunk. Each listen starts a new measurement session.

## What it measures

- **Frequency weighting** (`FrequencyWeighting.a`, `.c`, `.z`) per IEC 61672-1, within ±0.5 dB of the standard's design goals at ten frequencies from 31.5 Hz to 16 kHz, at 16, 44.1 and 48 kHz. At 16 kHz the Nyquist frequency is 8 kHz, so nothing above it can be measured, and the tested frequencies stop at 6.3 kHz.
- **Time weighting** (`TimeWeighting.fast`, `.slow`, `.impulse`): exponential averaging with 125 ms, 1 s, or 35 ms rise and 1.5 s decay. The meter starts from silence, so the first readings rise towards the true level.
- **Leq**: over the session (`leq`), the last second (`leq1s`) and the last 60 seconds (`leq60s`). The rolling windows have a 10 ms resolution, and cover the audio heard so far until they fill.
- **LevelCalibration**: `LevelCalibration.offsetDb` is added to every level.

## Decibel reference

Without calibration, 0 dB is the level of a full-scale sine (an RMS of 1/√2), so a full-scale 1 kHz sine reads 0 dB with every weighting. Phone microphones are not measurement microphones: to read dB SPL, measure a known source with a reference sound level meter and set the difference as the calibration offset. Uncalibrated readings are relative estimates.

Digital silence reads `LevelReading.floorDb` (-200 dB) plus the calibration offset, never negative infinity.
