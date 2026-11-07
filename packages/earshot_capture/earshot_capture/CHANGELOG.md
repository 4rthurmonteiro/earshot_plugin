# Changelog

## 0.1.0

- Microphone permission request: `MicrophonePermission.request()`.
- Float32 mono PCM stream at 16, 44.1 and 48 kHz: `EarshotCapture.pcm()`. Subscriptions share one microphone session, which stops when the last one is cancelled.
- Capture state changes: `EarshotCapture.stateChanges()` emits the current state first.
- Interruptions (calls, Siri, route and device changes) report `CaptureState.interrupted` and resume on their own.
- Unprocessed input: iOS `.measurement` mode, Android `UNPROCESSED` with a `VOICE_RECOGNITION` fallback.
- Stream errors are `CaptureException`s with a `CaptureErrorCode`.

## 0.0.1

- Initial API preview.
- Microphone permission status.
