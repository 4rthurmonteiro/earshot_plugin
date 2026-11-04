# 0003. Single native capture plugin shared by level and classifier

- Status: Accepted
- Date: 2026-11-04

## Context

The level meter and the classifier both need microphone PCM. Two microphone taps would duplicate native code and could conflict on the audio session.

## Decision

`earshot_capture` is the only plugin that opens the microphone. It delivers float32 mono PCM (`PcmChunk`) at the requested rate (16, 44.1 or 48 kHz). `earshot_level` and the `yamnet` backend consume that same stream.

- iOS uses the `.record` category with the `.measurement` mode, so no voice processing is applied.
- Android uses `UNPROCESSED` and falls back to `VOICE_RECOGNITION`. minSdk is 24.

The Apple SoundAnalysis backend should also be fed from this tap. A temporary separate `AVAudioEngine` is acceptable in 0.1.0 if it is documented, and it is consolidated in 0.2.0.

## Consequences

- There is one place for permissions, interruptions and background handling.
- The capture API must stay generic: no DSP and no file recording.
