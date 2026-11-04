# 0006. Package naming: by platform, umbrella is `earshot_plugin`

- Status: Accepted
- Date: 2026-11-04

## Context

Package names on pub.dev are permanent. The handover proposed `earshot_capture_ios`, `earshot_classifier_apple` and an umbrella package called `earshot`. Two things changed that:

- macOS is supported from 0.0.1.
- The bare name `earshot` is reserved for a future paid app.

## Decision

- Implementation packages are named after the platform, not the engine.
  - iOS and macOS share one package each, using `sharedDarwinSource`: `earshot_capture_darwin` and `earshot_classifier_darwin`.
  - Backends keep engine names (`ClassifierBackend.apple`, `ClassifierBackend.yamnet`).
- The classifier has no `_android` package. `earshot_classifier` declares `android: dartPluginClass` and registers the Dart YAMNet backend inline.
- The umbrella package is `earshot_plugin`, and the GitHub repo is `4rthurmonteiro/earshot_plugin`.
- `earshot_capture_ios` and `earshot_classifier_apple` are deliberately not reserved.

## Consequences

- Names are consistent across the capture and classifier families.
- pub.dev lists Android support for `earshot_classifier` without a separate package.
- The bare `earshot` name stays free.
