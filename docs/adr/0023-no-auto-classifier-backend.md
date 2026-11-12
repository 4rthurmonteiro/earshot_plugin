# 0023. A null backend instead of `ClassifierBackend.auto`

- Status: Accepted
- Date: 2026-11-12

## Context

`ClassifierBackend` has three values: `auto`, `apple` and `yamnet` (ADR 0011, ADR 0014). `apple` and `yamnet` name an engine. `auto` is a way to choose one, and never produces anything itself, so every API that takes a backend has to reject it:

- `SoundVocabulary.labels`, `soundOf` and `groupOf`, and `EarshotSound.labelsOf` and `isSupportedBy`, throw an `ArgumentError` for `auto`.
- The dartdoc of `SoundDetection.backend` has to say that it is "never `auto`".

Since the enum is open (ADR 0021), every new backend would go into the same type as the choice rule, and the type system can't tell the two apart. After 1.0.0, fixing this would need a major version.

## Decision

- **`ClassifierBackend` names engines only:** `apple` and `yamnet`.
- **`ClassifierOptions.backend` is a `ClassifierBackend?`** and defaults to `null`. `null` keeps the old meaning of `auto`: `apple` on iOS and macOS when `EarshotClassifierPlatform.isAvailable()` completes with `true`, and `yamnet` otherwise.
- **The vocabulary APIs** take a backend that always produces labels, and no longer throw for it.

This amends ADR 0011 and ADR 0014, where they describe the `auto` value.

## Consequences

- Apps that passed `ClassifierBackend.auto` remove the argument, or pass `null`. Apps that never set a backend don't change.
- `SoundDetection.backend` and the vocabulary APIs can no longer receive a value they have to reject.
- A switch on `ClassifierBackend` covers only engines.
