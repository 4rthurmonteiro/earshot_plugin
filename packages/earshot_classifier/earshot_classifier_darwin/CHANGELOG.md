# Changelog

## 0.1.0 (unreleased)

- Follow the new `EarshotClassifierPlatform` API (`isAvailable`, `detections(ClassifierConfig)`).
- Implement the Apple SoundAnalysis backend on iOS 15+ and macOS 12+: `SNClassifySoundRequest` (version 1) on an `AVAudioEngine` input tap, through Pigeon. `auto` now picks it on iOS and macOS.
- Each `listen()` gets its own analyzer session; concurrent sessions share one input tap. Cancelling the last one releases the microphone.
- Stream errors are `CaptureException`s (`permissionDenied`, `audioUnavailable`, `unknown`). Classification never prompts for the microphone permission.
- Handle interruptions as `earshot_capture` does: the engine restarts after calls, Siri, media services resets and device changes.
- On iOS, share the app's audio session with the other earshot plugin: stopping capture or classification no longer stops the other (ADR 0017).

## 0.0.1

- Initial API preview.
