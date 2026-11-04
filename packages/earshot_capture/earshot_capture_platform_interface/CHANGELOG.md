# Changelog

## 0.1.0 (unreleased)

- Add `CaptureException` and `CaptureErrorCode`.
- Add `CaptureMultiplexer`, which shares one native capture session between `pcm()` subscriptions, for implementations.
- Document that `stateChanges()` emits the current state first and that each subscription's timestamps start at zero.

## 0.0.1

- Initial API preview.
