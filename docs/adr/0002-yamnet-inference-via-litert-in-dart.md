# 0002. YAMNet inference via LiteRT in Dart

- Status: Accepted
- Date: 2026-11-04

## Context

There is no maintained cross-platform sound classifier on pub.dev. The alternatives were MediaPipe Tasks, which needs Kotlin/Swift ML glue for each platform, or LiteRT driven from Dart through FFI.

## Decision

The `yamnet` backend runs in Dart inside `earshot_classifier`:

- **Runtime:** LiteRT through `flutter_litert` (Apache-2.0, verified 2026-11-04), running in an isolate via `IsolateInterpreter`. The fallback is `tflite_flutter`, which has the same API.
- **Model:** `yamnet.tflite` float32 from the MediaPipe bucket (Apache-2.0), listed in `THIRD_PARTY_NOTICES.md` when it is bundled.
- **Input:** 15,600 samples at 16 kHz (0.975 s), with a 50% hop.
- **No Kotlin and no MediaPipe Tasks** for ML.

## Consequences

- The ML pipeline is a single Dart implementation that can be tested with WAV fixtures and runs on every platform.
- Native code is limited to audio capture.
- `flutter_litert` constrains the whole workspace, because pub workspaces resolve a single version of each dependency.
- Target performance is under 50 ms per window on a mid-range Android device. This has to be measured.
