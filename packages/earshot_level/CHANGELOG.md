# Changelog

## 0.1.0 (unreleased)

- `LevelMeter` now measures: it emits one `LevelReading` per non-empty `PcmChunk` at 16, 44.1 and 48 kHz.
- A, C and Z frequency weighting per IEC 61672-1, within ±0.5 dB of the standard's design goals at ten frequencies from 31.5 Hz to 16 kHz (to 6.3 kHz at a 16 kHz sample rate, whose Nyquist frequency is 8 kHz).
- Fast, Slow and Impulse time weighting.
- Leq over the session, the last second and the last 60 seconds.
- Calibration offset added to every level.
- Without calibration, 0 dB is the level of a full-scale sine. Digital silence reads `LevelReading.floorDb` (-200 dB) plus the calibration offset, never negative infinity.
- **Breaking:** `LevelReading` has two new required fields, `leq1s` and `leq60s`, which are part of `==`, `hashCode` and `toString`.
- `Response` has a new `decayTimeConstant` field (1.5 s for `Response.impulse`, equal to `timeConstant` otherwise).

## 0.0.1

- Initial API preview.
