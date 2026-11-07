# 0018. SoundAnalysis on the shared capture tap

- Status: Accepted
- Date: 2026-11-07
- Supersedes: the engine, permission and interruption parts of [0015](0015-soundanalysis-sessions-and-errors.md). Completes the consolidation planned in [0003](0003-single-native-capture-plugin.md) and [0014](0014-classifier-platform-interface-and-model-bundling.md).

## Context

In 0.1.0, `earshot_classifier_darwin` runs its own `AVAudioEngine` next to the one in `earshot_capture_darwin` (ADR 0015). That costs two microphone taps, a second copy of the interruption handling, and the shared audio session counter of ADR 0017. Detection timestamps also follow SoundAnalysis's clock rather than the capture clock that level readings use (ADR 0016).

The two plugins are separate Swift modules with no shared dependency, and Dart owns the only capture session through `CaptureMultiplexer` (ADR 0013). ADR 0014 planned the shared tap as a new platform method with a default.

## Decision

- **PCM goes through Dart.** `EarshotClassifierPlatform` gets `classify(Stream<PcmChunk> pcm, ClassifierConfig config)`, with a default that errors with `UnimplementedError`. `earshot_classifier_platform_interface` now depends on `earshot_capture_platform_interface` for `PcmChunk`. Both are pure Dart.
- **The darwin backend has no engine.** `EarshotClassifierDarwin.classify` starts a native session, listens to `pcm` and sends every chunk to the host with a new `analyze` call, as little-endian float32 bytes (the transport of ADR 0013, in the other direction). The host feeds each session's `SNAudioStreamAnalyzer` on one serial queue. It builds the analyzer from the first chunk's sample rate and rebuilds it when the rate changes or the timestamps jump, after an interruption. `detections(config)` classifies `EarshotCapturePlatform.instance.pcm` at 16 kHz, like the YAMNet backend.
- **Timestamps** are the chunk timestamps plus the window's position in the analyzer, so detections share the capture clock and gaps show up as jumps.
- **Permission, errors and interruptions belong to capture.** The darwin backend no longer reads the permission, opens the microphone, observes interruptions or touches the iOS audio session. Capture errors reach the stream unchanged, as `CaptureException`s. The host still ends a session with `unknown` when SoundAnalysis fails.
- **Backend selection.** `EarshotClassifier.classify` now honours `apple` and `auto` like `detections` does: on iOS and macOS, `apple` (and `auto` when SoundAnalysis is available) classifies the given PCM with SoundAnalysis. `earshot_plugin` always passes its shared capture stream to `classify`.
- **One audio session user.** `EarshotAudioSession.swift` stays only in `earshot_capture_darwin`, which is now its single user. The classifier's copy is removed.

## Consequences

- `Earshot.listen` uses one microphone tap on every platform and backend, and SoundAnalysis accepts any capture rate, so `apple` never hits `sampleRateConflict` in the umbrella.
- A standalone `detections()` on the apple backend joins the shared session at 16 kHz, so it now fails with `sampleRateConflict` while capture runs at another rate, as the YAMNet backend already did.
- Apple classification requires `earshot_capture` to be registered, which `earshot_classifier` guarantees through its dependency.
- PCM crosses the platform channel twice (host to Dart, Dart to host). At 16 to 48 kHz mono that is 64 to 192 kB/s, which is negligible.
- Interruptions pause detections through capture, which reports them on its state stream. Real-device testing is still needed.
