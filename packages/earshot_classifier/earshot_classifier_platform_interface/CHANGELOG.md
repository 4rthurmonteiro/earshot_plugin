# Changelog

## Unreleased

- **Breaking:** remove `ClassifierBackend.auto`. `ClassifierBackend` now names engines only, and the vocabulary APIs no longer throw an `ArgumentError` for a backend (ADR 0023).
- Document that `EarshotSound`, `SoundGroup` and `ClassifierBackend` can gain values in a minor version (ADR 0021).

## 0.2.0

- Add `EarshotClassifierPlatform.classify(Stream<PcmChunk>, ClassifierConfig)`, so native backends classify PCM from `earshot_capture` instead of opening their own microphone session (ADR 0018). It defaults to a stream that errors with `UnimplementedError`.
- `detections` now captures with `earshot_capture` too, and detection timestamps follow the PCM clock.
- Depend on `earshot_capture_platform_interface` for `PcmChunk`.

## 0.1.0

- Add `EarshotSound`, the cross-backend sound vocabulary. Each sound lists the Apple and YAMNet labels it maps to, validated against the official label lists.
- Add `SoundVocabulary` to map raw labels to sounds and groups. Unmapped labels fall back to their group, and silence is never reported.
- Add `SoundDetection.sound`.
- **BREAKING:** `EarshotClassifierPlatform.detections` takes a `ClassifierConfig` and reports raw, unsmoothed detections from the backend's own microphone session.
- Add `EarshotClassifierPlatform.isAvailable`.

## 0.0.1

- Initial API preview.
