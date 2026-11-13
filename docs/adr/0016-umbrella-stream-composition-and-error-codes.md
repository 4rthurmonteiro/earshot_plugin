# 0016. Umbrella stream composition and error codes

- Status: Accepted, classifier path amended by [0018](0018-soundanalysis-on-the-shared-capture-tap.md), error mapping amended by [0024](0024-classifier-exception.md)
- Date: 2026-11-04

## Context

`Earshot.listen` combines the level meter (`earshot_level`) and the classifier (`earshot_classifier`) into one stream of `EarshotEvent`s. ADR 0013 shares one native microphone session between subscriptions at one sample rate. ADR 0014 adds `EarshotClassifier.classify(Stream<PcmChunk>)` so that YAMNet can read PCM the app already captures, while Apple SoundAnalysis runs its own session until 0.2.0. Apps need one stable set of error codes, whatever produced the error.

## Decision

**One capture subscription.** Each `listen()` subscribes once to `EarshotCapture.pcm` at `EarshotOptions.capture` and fans every chunk out, in Dart, to the `LevelMeter` and, when the classifier reads PCM, to `EarshotClassifier.classify`. The chunk is shared, not copied: both consumers only read it.

**Classifier path.** `yamnet` always uses `classify`. `apple` uses `detections()`. `auto` uses `classify` off Apple platforms, where `detections()` would pick YAMNet anyway, and `detections()` on iOS and macOS, so that `earshot_classifier` keeps sole ownership of backend selection and availability. If SoundAnalysis is unavailable there, the classifier falls back to YAMNet on its own 16 kHz capture subscription, which joins the same native session.

**Sample rate.** The default stays at 16 kHz (`CaptureConfig()`). It is YAMNet's rate, so classification costs no resampling, and it matches the classifier's own 16 kHz fallback subscription, so that path never hits `sampleRateConflict`. At 16 kHz the level meter cannot measure above 8 kHz, which costs little for A-weighted ambient levels. Apps that want a full-band level choose 48 kHz, and YAMNet resamples (ADR 0014).

**Events.** With level metering on, each `LevelReading` is an event that carries the detections confirmed since the previous event, so the event rate follows the chunk rate. With it off, each detection is an event. When the stream ends, detections confirmed after the last reading are flushed in a final event without a level. With both off, the stream closes at once and opens nothing.

**Lifecycle.** Cancelling cancels the capture subscription and the classifier stream, which stop their native work through their own contracts. Pausing pauses them, so Dart buffers audio until resume.

**Errors.** The first error from any source ends the stream: it is delivered as one `EarshotException`, then the stream closes and everything is cancelled. The original error is kept as `cause`:

- `CaptureException` keeps its code (`permissionDenied`, `audioUnavailable`, `sampleRateConflict`, `unknown`).
- A `PlatformException` whose code is an `EarshotErrorCode` name gets that code, so native backends can report codes directly.
- `UnsupportedError`, including `UnimplementedError`, is `unsupported`.
- Anything else from the classifier is `modelUnavailable`, because the classifier fails only when its model cannot be loaded or run. Anything else from capture is `unknown`.

## Consequences

- One microphone session serves level and YAMNet, but the whole app shares one sample rate at a time.
- On Apple platforms with `apple`, or `auto` when SoundAnalysis is available, SoundAnalysis and capture run two engines in 0.1.0, and detection timestamps follow SoundAnalysis's clock rather than the level's. Moving SoundAnalysis to the shared tap in 0.2.0 removes both.
- With `auto` on Apple platforms, a capture rate other than 16 kHz fails with `sampleRateConflict` if SoundAnalysis is unavailable.
- Detections wait for the next level reading, a delay of up to one chunk.
