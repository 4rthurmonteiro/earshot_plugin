# 0017. Shared iOS audio session across the earshot plugins

- Status: Accepted, amended by [0018](0018-soundanalysis-on-the-shared-capture-tap.md)
- Date: 2026-11-05
- Amends: [0015](0015-soundanalysis-sessions-and-errors.md), which listed this as a known limitation.

## Context

On iOS, an app has one `AVAudioSession`. In 0.1.0, `earshot_capture_darwin` and `earshot_classifier_darwin` each run their own `AVAudioEngine` on it (the shared capture tap arrives in 0.2.0). Each plugin activated the session when it started and deactivated it when it stopped.

Deactivating the session stops every engine in the app. Testing the example on the iOS simulator showed the result: stopping `Earshot.listen` (SoundAnalysis) while a raw capture was running froze that capture. Its state stayed `capturing` and no more audio arrived.

The two plugins are separate Swift modules with no shared dependency, so neither can see the other's state directly.

## Decision

- Both plugins activate and release the session only through `EarshotAudioSession`, a small helper with `acquire()` and `release()`.
- `acquire()` sets the `.record` category with the `.measurement` mode, activates the session and counts one user. `release()` removes one user and deactivates the session (with `.notifyOthersOnDeactivation`) only when none is left.
- The count is stored in `Thread.main.threadDictionary` under the key `dev.earshot.audioSession.users`, so both modules share it. Access is serialized by locking the session object.
- The helper is one file, `EarshotAudioSession.swift`, copied identically into both packages. Each plugin tracks whether it currently holds the session, so it releases at most once.
- Restarts after interruptions still call `setActive(true)` directly. They don't change the count.

## Consequences

- Stopping one earshot engine no longer stops the other. The session is deactivated when the last one stops, so other apps can resume their audio.
- The two copies of `EarshotAudioSession.swift` must stay identical (AGENTS.md).
- Audio code outside earshot in the same app can still deactivate the session. That is outside earshot's control.
- The 0.2.0 shared capture tap leaves one engine. The helper can stay, or be removed then.
