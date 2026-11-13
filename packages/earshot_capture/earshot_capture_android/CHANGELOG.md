# Changelog

## Unreleased

- First stable release. The public API follows semantic versioning from now on: breaking changes only in a major version (ADR 0021).

## 0.1.0

- Microphone permission request through the foreground `Activity`.
- PCM capture with `AudioRecord` in `ENCODING_PCM_FLOAT` on a background thread, from `UNPROCESSED` when the device supports it and `VOICE_RECOGNITION` otherwise.
- Interruptions: silenced capture (calls, Android 10+) reports `interrupted` and drops the zeroed audio; a dead recorder is reopened with retries.
- Pigeon `@EventChannelApi` streams for PCM and state. Adds a `kotlinx-coroutines-android` dependency, which the generated `@async` host API needs.

## 0.0.1

- Initial API preview.
- Microphone permission status.
