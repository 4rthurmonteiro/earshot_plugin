# Changelog

## Unreleased

- **Breaking:** SoundAnalysis failures are delivered as a `ClassifierException` instead of a `CaptureException` with `CaptureErrorCode.unknown`: `unsupported` when SoundAnalysis cannot run on the OS or at the sample rate, and `modelUnavailable` when it fails while classifying (ADR 0024).

## 0.2.0

- SoundAnalysis now classifies PCM from `earshot_capture`, so classification and capture share one microphone tap (ADR 0018). The plugin no longer runs an `AVAudioEngine`, reads the microphone permission or touches the iOS audio session.
- Add `classify(pcm, config)`, which accepts every sample rate. `detections(config)` classifies 16 kHz PCM from `earshot_capture`, so it fails with `sampleRateConflict` while capture runs at another rate.
- Detection timestamps follow the PCM clock and jump over interruptions. Capture errors reach the stream unchanged.
- Remove the classifier's copy of `EarshotAudioSession.swift`.

## 0.1.0

- Follow the new `EarshotClassifierPlatform` API (`isAvailable`, `detections(ClassifierConfig)`).
- Implement the Apple SoundAnalysis backend on iOS 15+ and macOS 12+: `SNClassifySoundRequest` (version 1) on an `AVAudioEngine` input tap, through Pigeon. `auto` now picks it on iOS and macOS.
- Each `listen()` gets its own analyzer session; concurrent sessions share one input tap. Cancelling the last one releases the microphone.
- Stream errors are `CaptureException`s (`permissionDenied`, `audioUnavailable`, `unknown`). Classification never prompts for the microphone permission.
- Handle interruptions as `earshot_capture` does: the engine restarts after calls, Siri, media services resets and device changes.
- On iOS, share the app's audio session with the other earshot plugin: stopping capture or classification no longer stops the other (ADR 0017).

## 0.0.1

- Initial API preview.
