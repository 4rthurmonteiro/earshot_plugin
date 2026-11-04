# 0004. DSP in pure Dart

- Status: Accepted
- Date: 2026-11-04

## Context

A-weighting, C-weighting and Z-weighting, time constants, Leq, resampling and windowing could be done natively or in Dart.

## Decision

All of this DSP is implemented in pure Dart, in `earshot_level`, plus the resampler in the classifier. The specific techniques:

- **Weighting filters:** bilinear-transform IIR, with coefficients computed for the active sample rate.
- **Resampling:** polyphase FIR or windowed-sinc. Linear resampling is only a documented fallback.

## Consequences

- The DSP can be unit-tested against IEC 61672 (±0.5 dB at 10 frequencies) and against synthetic signals.
- The same code runs on every platform, and the math is reusable outside Flutter, for example as a firmware reference.
- CPU cost has to be measured on real devices.
