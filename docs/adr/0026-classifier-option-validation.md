# 0026. Classifier option validation

- Status: Accepted
- Date: 2026-11-13

## Context

`ClassifierOptions.minConfidence` must be between 0 and 1, and `Smoothing.hits` must be at least 1. The constructors check this with `assert`, which release builds skip. A release app with `minConfidence: 1.5` gets no detections, and one with `hits: 0` confirms every detection, without any error.

Throwing an `ArgumentError` from the constructors would fix this, but a `const` constructor can't throw. Dropping `const` from `ClassifierOptions`, `Smoothing` and `ClassifierConfig` would break every `const ClassifierOptions()` in apps, and the `const` defaults of `EarshotOptions`. Changing either the constructors or the failure behaviour is a breaking change from 1.0.0 (ADR 0021), so it has to be settled now.

## Decision

- **The constructors stay `const`** and keep their asserts, so debug builds still fail where the bad value is written.
- **`EarshotClassifier` validates its options on each `listen()`**, in every build. With invalid options, the stream delivers one `ArgumentError` and closes, before it opens a backend or listens to the PCM. NaN counts as invalid.
- **`earshot_plugin` maps an `ArgumentError` to `EarshotErrorCode.unknown`**, with the `ArgumentError` as `cause`. A classifier error that is not typed would otherwise become `modelUnavailable` (ADR 0016).
- **Backends still trust `ClassifierConfig`.** `EarshotClassifier` is the only entry point that builds one from app input.

## Consequences

- An invalid value always fails loudly, in debug at construction and in release at listen time.
- The failure is an `ArgumentError`, a programming error, rather than a `ClassifierException`, which is kept for runtime failures of a backend.
