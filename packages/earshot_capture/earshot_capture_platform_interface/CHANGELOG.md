# Changelog

## 1.0.0

- First stable release. The public API follows semantic versioning from now on: breaking changes only in a major version (ADR 0021).
- Document that `SampleRate`, `CaptureState`, `CaptureErrorCode` and `MicrophonePermissionStatus` can gain values in a minor version (ADR 0021).

## 0.1.0

- Add `CaptureException` and `CaptureErrorCode`.
- Add `CaptureMultiplexer`, which shares one native capture session between `pcm()` subscriptions, for implementations.
- Document that `stateChanges()` emits the current state first and that each subscription's timestamps start at zero.

## 0.0.1

- Initial API preview.
