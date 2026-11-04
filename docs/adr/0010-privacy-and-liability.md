# 0010. Privacy and liability posture

- Status: Accepted
- Date: 2026-11-04

## Context

A package that listens continuously to the microphone carries privacy risk and legal risk. Some sound groups, such as smoke and CO alarms, could be mistaken for safety devices.

## Decision

- No network access at runtime, and no telemetry.
- No audio is written to disk by default.
- Privacy manifests declare no data collection.
- Permission status queries never prompt the user.
- The README and the dartdoc for alarm-related types state that earshot is informational and is not a certified detector.

## Consequences

- The model is bundled with the package, never downloaded at runtime.
- Any future feature that needs network access or persistence must be opt-in and requires a new ADR.
