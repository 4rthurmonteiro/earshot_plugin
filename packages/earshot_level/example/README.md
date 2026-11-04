# earshot_level example

```dart
import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_level/earshot_level.dart';

final readings = const EarshotCapture().pcm().transform(
  const LevelMeter(options: LevelOptions(weighting: Weighting.a)),
);
```

A complete Flutter app that uses the earshot packages lives in [`examples/earshot_example`](https://github.com/4rthurmonteiro/earshot_plugin/tree/main/examples/earshot_example).
