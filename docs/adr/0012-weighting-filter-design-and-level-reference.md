# 0012. Weighting filter design and level reference

- Status: Accepted
- Date: 2026-11-04

## Context

[ADR 0004](0004-dsp-in-pure-dart.md) chose bilinear-transform IIR filters for the A and C weightings. Both weightings have a double pole at 12.2 kHz. The bilinear transform maps the whole analog frequency axis onto 0 Hz to Nyquist, so this pole is compressed near Nyquist: at 48 kHz a plain transform is several decibels off at 16 kHz, and at 16 kHz the pole lies above the 8 kHz Nyquist frequency and cannot be pre-warped at all. The target is ±0.5 dB of IEC 61672-1 at ten frequencies at every supported sample rate.

The readings also need a fixed decibel reference and a defined value for digital silence.

## Decision

- **Low-frequency poles:** the poles at 20.6 Hz (A and C), 107.7 Hz and 737.9 Hz (A), with their zeros at 0 Hz, are mapped to biquads with the bilinear transform, each pole pre-warped.
- **High-frequency pole pair:** the 12.2 kHz double pole is modelled by a 13-tap linear-phase FIR whose amplitude is fitted to the analog magnitude from 0 Hz to Nyquist by weighted least squares (weight `1/target²`, so the error is relative). The fit is computed when the meter sees a sample rate, so no coefficients are hard-coded.
- **Normalization:** the gain is set so the digital response is exactly 0 dB at 1 kHz. Z-weighting is a pass-through.
- **Reference:** without calibration, 0 dB is the level of a full-scale sine (an RMS of 1/√2). The calibration offset is added to every level.
- **Silence:** levels are floored at -200 dB before calibration, so digital silence never reads negative infinity.

## Consequences

- The digital weightings follow the analog ones within 0.15 dB from 10 Hz to 20 kHz (or just below Nyquist at 16 kHz), well inside ±0.5 dB of the IEC design goals. At 16 kHz nothing above 8 kHz can be measured; that is a limit of the sample rate, not of the filter.
- The FIR adds 6 samples of delay, which is irrelevant for a level meter, and 13 multiply-adds per sample.
- The pure Dart, no-native-code decision of ADR 0004 stands. This ADR refines its filter technique.
