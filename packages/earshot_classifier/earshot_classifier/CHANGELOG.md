# Changelog

## Unreleased

- Document that `EarshotSound`, `SoundGroup` and `ClassifierBackend` can gain values in a minor version, and show a `switch` with a wildcard case (ADR 0021).

## 0.2.0

- `EarshotClassifier.classify(pcm)` now picks the backend like `detections()`: `apple`, and `auto` on iOS and macOS when SoundAnalysis is available, run SoundAnalysis on the given PCM. `apple` no longer errors there.
- The `apple` backend of `detections()` captures with `earshot_capture` instead of opening its own microphone session.

## 0.1.0

- **BREAKING:** `EarshotClassifier.detections()` now classifies. It picks the backend from `ClassifierOptions.backend`, drops detections below `minConfidence` and applies `Smoothing`.
- Add the `yamnet` backend: YAMNet float32 through LiteRT (`flutter_litert`) in a background isolate, on Android, iOS and macOS. The model is bundled as an asset (see `THIRD_PARTY_NOTICES.md`).
- Add backend selection: `auto` uses the platform backend on iOS and macOS when it is available, and YAMNet otherwise.
- Add `EarshotClassifier.classify(Stream<PcmChunk>)` to classify PCM the app already captures. PCM at 44.1 or 48 kHz is resampled to 16 kHz.
- Export `EarshotSound` and `SoundVocabulary`.

## 0.0.1

- Initial API preview.
