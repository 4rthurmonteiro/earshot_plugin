# Changelog

## 0.1.0

- Add `EarshotSound`, the cross-backend sound vocabulary. Each sound lists the Apple and YAMNet labels it maps to, validated against the official label lists.
- Add `SoundVocabulary` to map raw labels to sounds and groups. Unmapped labels fall back to their group, and silence is never reported.
- Add `SoundDetection.sound`.
- **BREAKING:** `EarshotClassifierPlatform.detections` takes a `ClassifierConfig` and reports raw, unsmoothed detections from the backend's own microphone session.
- Add `EarshotClassifierPlatform.isAvailable`.

## 0.0.1

- Initial API preview.
