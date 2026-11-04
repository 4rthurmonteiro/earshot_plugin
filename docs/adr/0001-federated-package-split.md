# 0001. Federated package split

- Status: Accepted
- Date: 2026-11-04

## Context

earshot answers two questions on-device: how loud it is (dB) and what is sounding (classification). Many apps only need the level meter and shouldn't have to ship a ~4 MB ML model or ML dependencies. iOS, macOS and Android need different native code.

## Decision

Use Flutter federated plugins and split the repo into independent packages:

- `earshot_capture` family: `earshot_capture`, `earshot_capture_platform_interface`, `earshot_capture_android` and `earshot_capture_darwin`. It provides microphone access only.
- `earshot_level`: pure Dart dB metering built on top of capture.
- `earshot_classifier` family: `earshot_classifier`, `earshot_classifier_platform_interface` and `earshot_classifier_darwin`.
- `earshot_plugin`: an umbrella package that combines level and classification in one stream.

Platform interfaces are pure Dart, with no MethodChannel default. On platforms that aren't endorsed, the default instance is an `Unsupported*` stub.

## Consequences

- Apps that only need dB depend on `earshot_level` and pull in no model.
- Each package is versioned and published on its own, so the publish order matters (see AGENTS.md).
- Because the platform interfaces are pure Dart, `earshot_level` can stay pure Dart too.
