# earshot_classifier example

```dart
import 'package:earshot_classifier/earshot_classifier.dart';

const EarshotClassifier().detections().listen((detection) {
  print('${detection.group}: ${detection.rawLabel}');
});
```

A complete Flutter app that uses the earshot packages lives in [`examples/earshot_example`](https://github.com/4rthurmonteiro/earshot_plugin/tree/main/examples/earshot_example).
