# Changelog

## Unreleased

- Document that capture is now the only user of the shared iOS audio session (ADR 0018). Behaviour is unchanged.

## 0.1.0

- Microphone permission request: `AVAudioApplication` (iOS 17+) or `AVAudioSession` on iOS, `AVCaptureDevice` on macOS.
- PCM capture with an `AVAudioEngine` input tap, converted to mono float32 at the requested rate with `AVAudioConverter`. iOS uses the `.record` category with the `.measurement` mode.
- Interruptions: audio session interruptions, media services resets and route changes on iOS, engine configuration changes on iOS and macOS. Capture restarts on its own.
- Pigeon `@EventChannelApi` streams for PCM and state.
- On iOS, share the app's audio session with the other earshot plugin: stopping capture or classification no longer stops the other (ADR 0017).

## 0.0.1

- Initial API preview.
- Microphone permission status.
