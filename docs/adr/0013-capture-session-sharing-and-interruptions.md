# 0013. Capture session sharing, errors and interruptions

- Status: Accepted
- Date: 2026-11-04

## Context

0.1.0 implements the PCM stream. AGENTS.md requires that each `listen()` gets its own subscription and that cancelling it stops the native work. The microphone is one device, though: Android cannot reliably run two `AudioRecord`s in one app before Android 10, and an `AVAudioEngine` input node has one tap per bus. Pigeon's `@EventChannelApi` methods take no parameters, and a second `receiveBroadcastStream()` on the same channel steals the first one's messages.

Stream errors need a type that `earshot_plugin` can map to `EarshotErrorCode`, and the interruption behaviour has to be decided per platform.

## Decision

- **One native session, shared in Dart.** The host owns at most one capture session, driven by `startCapture(config)` and `stopCapture()`, and pushes PCM and state on two `@EventChannelApi` streams. `CaptureMultiplexer`, in the platform interface, gives every `pcm()` subscription its own stream, starts the host on the first `listen()` and stops it when the last subscription is cancelled. Host calls are serialized, so a stop never overtakes a start.
- **One sample rate at a time.** A subscription at a different rate while capture runs fails with `CaptureErrorCode.sampleRateConflict`. Consumers that need another rate resample in Dart (ADR 0004), for example a 48 kHz session feeding both the level meter and YAMNet.
- **Timestamps.** The host stamps chunks by frame count since the session started, and rebases them after an interruption, so gaps show up as jumps. Each subscription's first chunk is at zero.
- **Errors.** Stream errors are `CaptureException(CaptureErrorCode)`: `permissionDenied`, `audioUnavailable`, `sampleRateConflict` or `unknown`. The host reports them as Pigeon errors with the code's name. An error ends every subscription. Permission calls keep forwarding `PlatformException`, as in 0.0.1.
- **Transport.** Pigeon has no `Float32List`, so samples travel as little-endian float32 bytes in a `Uint8List` and are copied into a `Float32List` in Dart.
- **Interruptions, Apple.** On iOS, an audio session interruption stops capture and reports `interrupted` until it ends (or the app becomes active again, because some interruptions end without notice). Media services resets rebuild the engine. On iOS and macOS, an engine configuration change (new device, rate or channel count) reinstalls the tap. Restarts are retried 10 times, 0.5 s apart, before the stream fails with `audioUnavailable`.
- **Interruptions, Android.** Audio focus is not requested: it is a playback concept, and requesting it would pause the user's music. From Android 10, `AudioRecordingConfiguration.isClientSilenced()` reports calls and other privileged capture; the zeroed audio is dropped and the state is `interrupted`. A recorder that fails (for example after an audio server restart) is reopened with the same retry policy.

## Consequences

- Concurrent consumers cost one microphone session, but they must agree on a sample rate.
- Before Android 10, a call may deliver silence or an error instead of an `interrupted` state.
- The interruption paths need testing on real devices, which CI cannot do.
- Apple SoundAnalysis still runs its own engine in 0.1.0, as ADR 0003 allows.
