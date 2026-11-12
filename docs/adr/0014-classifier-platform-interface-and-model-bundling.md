# 0014. Classifier platform interface, vocabulary data and model bundling

- Status: Accepted, amended by 0023
- Date: 2026-11-04
- Amends: [0011](0011-sound-vocabulary.md). Neither backend has a carbon monoxide alarm label, so under 0011's own inclusion rule the vocabulary has no CO sound. The maintainer accepted this on 2026-11-04.

## Context

ADR 0002 runs YAMNet in Dart and ADR 0011 defines the vocabulary, the backends and smoothing. Neither says how a native backend such as SoundAnalysis plugs in, where the vocabulary data lives, or how the model ships. In 0.1.0 SoundAnalysis runs its own `AVAudioEngine` (ADR 0003), and in 0.2.0 it moves to the shared capture tap.

## Decision

**Platform interface.** `EarshotClassifierPlatform` describes a backend that runs its own microphone session:

- `Future<bool> isAvailable()` must never prompt the user. For `auto`, `earshot_classifier` treats `false` or an error as unavailable.
- `Stream<SoundDetection> detections(ClassifierConfig config)`: each `listen()` opens a session, and cancelling it stops the session. The stream reports every label at or above `config.minConfidence` in each analysis window, built with `SoundVocabulary.detection`. It never throws synchronously and is not smoothed.

`earshot_classifier` owns backend selection, the confidence threshold and `Smoothing`, so every backend behaves the same way:

- `yamnet`: `EarshotClassifierYamnet`, in Dart, on every platform.
- `apple`: `EarshotClassifierPlatform.instance`, on iOS and macOS only.
- `auto`: `apple` on iOS and macOS when `isAvailable()` completes with `true`, and `yamnet` otherwise.

`EarshotClassifier.classify(Stream<PcmChunk>)` runs YAMNet on PCM the app already captures, so `earshot_plugin` can share one capture stream between level and classification.

The 0.2.0 shared tap is added as a new platform method with a default. That is not breaking, because implementations `extend` the interface.

**Vocabulary data.** The ADR 0011 "data file" is Dart const data in `earshot_classifier_platform_interface/lib/src/vocabulary/`:

- `EarshotSound` carries each sound's group, display name and labels.
- One table per backend lists every label with its fallback group.

Dart rather than JSON keeps the platform interface pure Dart with no asset loading, and the compiler rejects duplicate labels. The official lists and their provenance live in `tools/vocab/`, and a test in the platform interface validates the data against them.

**Model bundling.** `yamnet.tflite` (float32, about 4 MB, Apache-2.0, from the MediaPipe bucket) ships as a Flutter asset of `earshot_classifier`, listed in its `THIRD_PARTY_NOTICES.md`. It is never downloaded at runtime (ADR 0010). Each session loads the model and runs it in an `IsolateInterpreter`. `LiteRtYamnetInterpreter` is the only code that touches LiteRT, behind an internal `YamnetInterpreter` seam.

**Resampling.** 44.1 and 48 kHz PCM is resampled to 16 kHz with an exact rational polyphase windowed-sinc filter (Blackman, 16 zero crossings, cutoff at 95% of 8 kHz), as allowed by ADR 0004.

## Consequences

- The darwin backend implements `isAvailable` and `detections` in Swift plus Pigeon. Labels are mapped in Dart with `SoundVocabulary`, so Swift never needs the vocabulary.
- Every app that uses `earshot_classifier` ships the model, including iOS and macOS apps that use only `apple`. Apps that only need the level meter use `earshot_level` and ship no model (ADR 0001).
- Neither backend has a carbon monoxide alarm label, so `EarshotSound` has `smokeAlarm` and no CO sound. A CO alarm is reported as `smokeAlarm`, `beep` or `alarm`.
- Under `flutter test` in a pub workspace, flutter_litert finds its native library only when the working directory is the workspace root. The real-model test switches to it and runs outside very_good's test optimization.
