# 0015. SoundAnalysis sessions, errors and permission

- Status: Accepted, amended by [0017](0017-shared-ios-audio-session.md)
- Date: 2026-11-04

## Context

ADR 0014 says each `listen()` on `EarshotClassifierPlatform.detections` opens its own session, and ADR 0003 lets SoundAnalysis run its own `AVAudioEngine` in 0.1.0. An `AVAudioEngine` input node has one tap per bus, and Pigeon's `@EventChannelApi` methods take no parameters, so one event channel has to serve every session (ADR 0013). ADR 0014 also leaves open how the darwin backend reports errors and whether it may prompt for the microphone.

## Decision

- **Per-session analyzers, one tap.** Dart gives every `listen()` a session id and calls `startSession(id, minConfidence)` and `stopSession(id)`. The host runs one `AVAudioEngine` input tap while at least one session runs, and gives each session its own `SNAudioStreamAnalyzer` and `SNClassifySoundRequest(classifierIdentifier: .version1)`. Analyzers run on one serial queue. A session that joins a running engine starts at frame zero.
- **One event channel, tagged events.** Every event carries its session id: the classifications of one window at or above the session's `minConfidence` (identifier and confidence only, as ADR 0014 requires), the window start in microseconds, or an error that ends the session. Dart listens to a single `classifierEvents()` stream and routes events by id. Each session subscribes before it starts, and its stop waits for its start, so a stop never overtakes a start.
- **SoundAnalysis defaults.** `ClassifierConfig` has no window or overlap, so the request keeps its default window (about one second) and overlap (half).
- **Errors reuse `CaptureException`.** Stream errors are `CaptureException(CaptureErrorCode)` from `earshot_capture_platform_interface`, as for the YAMNet backend, which forwards `earshot_capture` errors. `earshot_plugin` maps one type for every backend. The host uses `permissionDenied`, `audioUnavailable` (the microphone cannot be opened, or reopened after an interruption) and `unknown` (SoundAnalysis failed).
- **No prompt.** Like `startCapture`, `startSession` fails with `permissionDenied` unless microphone access is already granted. Apps request it with `EarshotCapture.requestMicrophonePermission()`. `isAvailable()` only checks that the version 1 classifier can be created.
- **Interruptions** follow ADR 0013 on the shared engine: an interruption stops the engine, the restart rebuilds every analyzer for the new input format, and timestamps are rebased on the time since each session started. After 10 failed restarts, 0.5 s apart, every session fails with `audioUnavailable`. There is no state stream: detections just pause.

## Consequences

- Concurrent apple sessions cost one microphone tap, and each keeps its own threshold.
- Classification and `earshot_capture` still run two engines in one iOS audio session. Both use `.record` and `.measurement`. ADR 0017 makes them share the session so that stopping one no longer interrupts the other. The 0.2.0 shared capture tap leaves a single engine.
- The interruption paths need testing on real devices, which CI cannot do.
