# 0025. Level type names

- Status: Accepted
- Date: 2026-11-13

## Context

`earshot_level` exports three types with generic names: `Weighting`, `Response` and `Calibration`. `earshot_plugin` re-exports them, so they land in the namespace of every app that imports it. `Response` clashes with the `Response` of `package:http` and `package:dio`, which many apps import. Such an app then has to hide or prefix one of the two imports. The other two names say less than they could: IEC 61672-1 calls them frequency weighting and time weighting, and the calibration only applies to levels.

Renaming them is a breaking change from 1.0.0 (ADR 0021).

## Decision

| Before | After |
| --- | --- |
| `Weighting` | `FrequencyWeighting` |
| `Response` | `TimeWeighting` |
| `Calibration` | `LevelCalibration` |
| `LevelOptions.response` | `LevelOptions.timeWeighting` |

- **The values and members don't change.** `LevelOptions.weighting`, `LevelOptions.calibration` and `LevelReading.weighting` keep their short names: their types now say which weighting and which calibration they are.
- **The internal time weighting filter**, which used the name `TimeWeighting`, becomes `TimeWeightingFilter`, next to `WeightingFilter`.
- **The closed enums of ADR 0021** are now `FrequencyWeighting` and `TimeWeighting`.

## Consequences

- Apps can import `earshot_plugin` next to `http` or `dio` without hiding a name.
- Apps rename the three types and the `response:` argument. Nothing else changes.
