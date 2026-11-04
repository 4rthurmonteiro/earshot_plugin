# Changelog

## 0.1.0 (unreleased)

- **BREAKING:** `EarshotClassifier.detections()` now classifies. It picks the backend from `ClassifierOptions.backend`, drops detections below `minConfidence` and applies `Smoothing`.
- Add the `yamnet` backend: YAMNet float32 through LiteRT (`flutter_litert`) in a background isolate, on Android, iOS and macOS. The model is bundled as an asset (see `THIRD_PARTY_NOTICES.md`).
- Add backend selection: `auto` uses the platform backend on iOS and macOS when it is available, and YAMNet otherwise.
- Add `EarshotClassifier.classify(Stream<PcmChunk>)` to classify PCM the app already captures. PCM at 44.1 or 48 kHz is resampled to 16 kHz.
- Export `EarshotSound` and `SoundVocabulary`.

## 0.0.1

- Initial API preview.
