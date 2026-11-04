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
| [0009](0009-api-preview-0-0-1.md) | 0.0.1 is an API preview, not a name placeholder | Accepted |
| [0010](0010-privacy-and-liability.md) | Privacy and liability posture | Accepted |
| [0011](0011-sound-vocabulary.md) | Sound vocabulary and classifier backends | Accepted |
| [0012](0012-weighting-filter-design-and-level-reference.md) | Weighting filter design and level reference | Accepted |
| [0014](0014-classifier-platform-interface-and-model-bundling.md) | Classifier platform interface, vocabulary data and model bundling | Accepted |

## Template

```md
# NNNN. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```
