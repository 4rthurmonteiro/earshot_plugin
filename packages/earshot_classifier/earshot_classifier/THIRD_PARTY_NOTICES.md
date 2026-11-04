# Third-party notices

`earshot_classifier` is MIT-licensed (see [LICENSE](LICENSE)). It bundles or derives from the following third-party material.

## YAMNet model (`assets/yamnet.tflite`)

- **What:** the YAMNet audio event classifier, float32 TensorFlow Lite build, used by the `yamnet` backend.
- **Source:** MediaPipe model bucket, `https://storage.googleapis.com/mediapipe-models/audio_classifier/yamnet/float32/latest/yamnet.tflite`, downloaded on 2026-11-04.
- **SHA-256:** `4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf`
- **Copyright:** Google LLC.
- **License:** Apache License 2.0, <https://www.apache.org/licenses/LICENSE-2.0>.
- **Changes:** none. The file is bundled as published.

## YAMNet class map

- **What:** the 521 YAMNet class names, in model output order. They are reproduced in `earshot_classifier_platform_interface` (`lib/src/vocabulary/yamnet_labels.dart`) and kept as `tools/vocab/yamnet_class_map.csv` in the repository.
- **Source:** `yamnet_class_map.csv` from the tensorflow/models repository, `https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv`.
- **Copyright:** The TensorFlow Authors.
- **License:** Apache License 2.0, <https://www.apache.org/licenses/LICENSE-2.0>.
- **Changes:** only the `display_name` column is used, and each class is paired with an earshot sound group.

## Runtime

Inference uses [`flutter_litert`](https://pub.dev/packages/flutter_litert) (Apache License 2.0), which bundles the LiteRT / TensorFlow Lite runtime. It is a regular pub dependency and ships its own notices.
