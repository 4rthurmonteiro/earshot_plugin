# Changelog

## 0.1.0

- `Earshot.listen` now listens: one capture subscription feeds the level meter and, with the YAMNet backend, the classifier, and the stream emits `EarshotEvent`s. With level metering on, each level reading is an event that carries the sounds confirmed since the previous one. With it off, each confirmed sound is an event. The `apple` backend, and `auto` on iOS and macOS, use `EarshotClassifier.detections()`, which runs its own microphone session in 0.1.0.
- Cancelling a subscription stops capture, the level meter and the classifier; pausing it pauses them. Setting both `level` and `classifier` to `null` gives a stream that closes at once.
- Stream errors are `EarshotException`s, and the stream closes after the first one. `CaptureException` codes, `UnsupportedError`s and classifier failures map to `EarshotErrorCode`s.
- Add `EarshotErrorCode.sampleRateConflict`.
- Add `EarshotException.cause`, an optional third positional argument that keeps the original error. It takes part in `==` and `hashCode`.
- Document the timestamps of `EarshotEvent` and the 16 kHz default capture rate of `EarshotOptions.capture`.
- Accept the 0.1.x releases of `earshot_capture`, `earshot_classifier` and `earshot_level`.
- Tests build `LevelReading` with the new `leq1s` and `leq60s` fields of `earshot_level`.

## 0.0.1

- Initial API preview.
