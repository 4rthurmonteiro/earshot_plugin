# 0022. YAMNet performance benchmark

- Status: Accepted
- Date: 2026-11-12

## Context

The 1.0.0 checklist asks for YAMNet to run in under 50 ms per window on a mid-range Android device. YAMNet classifies a 0.975 s window every 0.4875 s (ADR 0002). Inference runs in a background isolate, so a slow window doesn't block the UI, but windows queue up and detections fall behind if one takes longer than the hop. 50 ms per window, about 10% of the hop, leaves room for the rest of an app, for a device that is busy, and for the level meter.

Without a defined method, "under 50 ms" can't be checked or compared across releases: debug builds are many times slower than release builds, the first window includes loading the model, and a microphone run depends on the room and on the permission.

## Decision

- **Harness.** `examples/earshot_example/integration_test/yamnet_benchmark_test.dart` runs `runYamnetBenchmark` from the example app. It uses only the public API: `EarshotClassifier.classify` with the `yamnet` backend, every label reported (`minConfidence: 0`) and no smoothing (`Smoothing(hits: 1)`). It never opens the microphone.
- **Input.** Deterministic white noise at 16 kHz, long enough for 120 windows, queued at once. Inference time does not depend on the content, and with a full queue the gap between the detections of two consecutive windows is the time one window took.
- **What a window time covers.** The inference in the isolate, copying data in and out, mapping the 521 scores to detections, and the classifier stream. It does not cover resampling, which happens when PCM arrives at 44.1 or 48 kHz, or capture.
- **Statistics.** The first window, which includes loading the model, is reported on its own. The next 5 gaps are a warm-up and are left out. The p50, p95, max and mean of the remaining 114 gaps are reported.
- **Target.** p95 under 50 ms, in profile mode, on a mid-range Android device: a phone sold in the middle of the market within the last three years, such as a Galaxy A35 or A55 or a Pixel 7a. Other devices are measured for information.
- **How to run it.** From `examples/earshot_example`:

  ```sh
  flutter drive --profile -d <device> \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/yamnet_benchmark_test.dart
  ```

  The driver writes the result to `build/yamnet_benchmark.json`.
- **Where results go.** The Performance section of the `earshot_classifier` README lists each measured device, with its OS, the earshot version, and the p50, p95 and first-window times. The 1.0.0 checklist item is ticked once a mid-range Android device meets the target.
- **Not in CI.** CI has no real devices, and emulator timings are meaningless. The maintainer runs the benchmark before a release that changes the YAMNet pipeline, LiteRT or the model.

## Consequences

- Any contributor can reproduce a measurement with one command, without a microphone or a permission prompt.
- The numbers cover the classifier, not a whole listening session. If a session ever falls behind with a fast classifier, resampling and capture need their own measurement.
- LiteRT runs on the CPU with its default threads. If a device misses the target, delegates and thread counts are the first things to try, in a new ADR.
