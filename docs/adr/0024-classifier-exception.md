# 0024. Typed classifier errors

- Status: Accepted
- Date: 2026-11-13

## Context

Capture delivers its failures as a `CaptureException` with a `CaptureErrorCode` (ADR 0013). The classifier has no error type of its own, so an app that uses `earshot_classifier` directly gets whatever the backend raised:

- an `UnsupportedError` for the `apple` backend off iOS and macOS;
- the raw LiteRT error when YAMNet fails to load or run;
- a `CaptureException` with `CaptureErrorCode.unknown` when SoundAnalysis fails, although the microphone is fine.

Only `earshot_plugin` turns these into an `EarshotErrorCode`, by guessing from the error type and from which source raised it (ADR 0016). Changing the type of an error delivered on a stream is a breaking change from 1.0.0 (ADR 0021), so this has to be settled before then.

## Decision

- **The classifier platform interface adds `ClassifierException`**, with a `ClassifierErrorCode`, alongside a message. It is a value type, like `CaptureException`.
  - `unsupported`: the backend can't run on this platform, OS version or sample rate.
  - `modelUnavailable`: the model failed to load, or failed while classifying.
  - `unknown`: any other failure.

  `ClassifierErrorCode` is an open enum (ADR 0021).
- **A classifier stream delivers exactly two kinds of error.** A `CaptureException` from the PCM it reads is forwarded unchanged. Every failure of the backend itself is a `ClassifierException`. The platform interface contract requires this of every backend.
- **`EarshotClassifier`** enforces the contract for any backend. It turns the errors that are not one of these two into a `ClassifierException`:
  - an `UnsupportedError`, including an `UnimplementedError`, is `unsupported`;
  - a `PlatformException` whose code names a `ClassifierErrorCode` gets that code;
  - anything else is `unknown`.
- **YAMNet** reports a model that fails to load or run as `modelUnavailable`.
- **SoundAnalysis** reports `unsupported` when it cannot run on the OS or at the sample rate, and `modelUnavailable` when it fails while classifying. These are the codes the Swift side now sends.
- **`earshot_plugin`** maps the codes one to one: `unsupported`, `modelUnavailable` and `unknown` keep their names as `EarshotErrorCode`s.

This amends ADR 0016, where it maps classifier errors by type.

## Consequences

- Apps that use `earshot_classifier` alone can switch on a code, like apps that use capture.
- A SoundAnalysis failure is no longer reported as a capture failure.
- Code that caught `UnsupportedError` or a `CaptureException` from the classifier has to catch `ClassifierException` instead.
- Until the next release raises the sibling constraints, `earshot_classifier`, `earshot_classifier_darwin` and `earshot_plugin` resolve to a published platform interface without `ClassifierException` in pana's downgrade check, which then fails (ADR 0019).
