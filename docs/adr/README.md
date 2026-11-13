# Architecture Decision Records

Each file records one decision: the context, what was decided, and its consequences. ADRs are immutable once accepted. To change a decision, add a new ADR that supersedes the old one and set the old one's status to `Superseded by NNNN`.

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-federated-package-split.md) | Federated package split | Accepted |
| [0002](0002-yamnet-inference-via-litert-in-dart.md) | YAMNet inference via LiteRT in Dart | Accepted |
| [0003](0003-single-native-capture-plugin.md) | Single native capture plugin shared by level and classifier | Accepted |
| [0004](0004-dsp-in-pure-dart.md) | DSP in pure Dart | Accepted |
| [0005](0005-melos-on-pub-workspaces.md) | Melos 8 on Dart pub workspaces | Accepted |
| [0006](0006-package-naming.md) | Package naming: by platform, umbrella is `earshot_plugin` | Accepted |
| [0007](0007-swift-package-manager-with-podspec-fallback.md) | Swift Package Manager with CocoaPods fallback | Accepted |
| [0008](0008-pigeon-private-to-implementation-packages.md) | Pigeon, private to implementation packages | Accepted |
| [0009](0009-api-preview-0-0-1.md) | 0.0.1 is an API preview, not a name placeholder | Superseded by 0021 |
| [0010](0010-privacy-and-liability.md) | Privacy and liability posture | Accepted |
| [0011](0011-sound-vocabulary.md) | Sound vocabulary and classifier backends | Accepted, amended by 0014 and 0023 |
| [0012](0012-weighting-filter-design-and-level-reference.md) | Weighting filter design and level reference | Accepted |
| [0013](0013-capture-session-sharing-and-interruptions.md) | Capture session sharing, errors and interruptions | Accepted |
| [0014](0014-classifier-platform-interface-and-model-bundling.md) | Classifier platform interface, vocabulary data and model bundling | Accepted, amended by 0023 |
| [0015](0015-soundanalysis-sessions-and-errors.md) | SoundAnalysis sessions, errors and permission | Accepted, amended by 0017, partly superseded by 0018 |
| [0016](0016-umbrella-stream-composition-and-error-codes.md) | Umbrella stream composition and error codes | Accepted, amended by 0018 and 0024 |
| [0017](0017-shared-ios-audio-session.md) | Shared iOS audio session across the earshot plugins | Accepted, amended by 0018 |
| [0018](0018-soundanalysis-on-the-shared-capture-tap.md) | SoundAnalysis on the shared capture tap | Accepted |
| [0019](0019-pana-in-ci.md) | pana in CI | Accepted |
| [0020](0020-release-versioning-with-melos-version.md) | Release versioning with melos version | Accepted, amended by 0027 |
| [0021](0021-public-api-stability-from-1-0-0.md) | Public API stability from 1.0.0 | Accepted, amended by 0025 |
| [0022](0022-yamnet-performance-benchmark.md) | YAMNet performance benchmark | Accepted |
| [0023](0023-no-auto-classifier-backend.md) | A null backend instead of `ClassifierBackend.auto` | Accepted |
| [0024](0024-classifier-exception.md) | Typed classifier errors | Accepted |
| [0025](0025-level-type-names.md) | Level type names | Accepted |
| [0026](0026-classifier-option-validation.md) | Classifier option validation | Accepted |
| [0027](0027-github-release-on-publish.md) | A GitHub release on every publish | Accepted |

## Template

```md
# NNNN. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```
