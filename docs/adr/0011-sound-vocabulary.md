# 0011. Sound vocabulary and classifier backends

- Status: Accepted, amended by [0014](0014-classifier-platform-interface-and-model-bundling.md) (no carbon monoxide alarm sound)
- Date: 2026-11-04

## Context

Apple SoundAnalysis has 303 labels and YAMNet has 521. Their confidence scores can't be compared with each other. Users need stable, cross-backend sound identifiers.

## Decision

- **Backends:** `auto` (apple on iOS/macOS, yamnet elsewhere), `apple` and `yamnet`. Users who want consistent results across platforms pick `yamnet` everywhere.
- **Vocabulary:** complete from the start, including smoke and CO alarms. It covers groups `people`, `animals`, `home`, `alarms`, `vehicles`, `tools`, `music`, `nature` and `other`.
- **Data file:** the mapping lives in a data file. Each `EarshotSound` lists its group, display name, and the apple and yamnet labels it maps to.
- **Inclusion rule:** a sound is included if at least one backend has it.
- **Validation:** a validator in `tools/vocab` checks every label against the official label lists. A test fails if a label doesn't exist or a sound has no backend.
- **Unmapped labels:** they fall back to their group, and `rawLabel` is always exposed.
- **Smoothing:** a detection is confirmed only after N hits within T seconds. The default is 2 hits within 2 seconds.

## Consequences

- `EarshotSound` is an enum, so renaming a value is breaking. Names must be reviewed before 0.1.0.
