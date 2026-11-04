# earshot_plugin example

```dart
import 'package:earshot_plugin/earshot_plugin.dart';

await const MicrophonePermission().request();

const Earshot().listen().listen(
  (event) => print('${event.level?.db} dB(A), ${event.detections}'),
  onError: (Object error) => print(error),
);
```

A complete Flutter app that uses the earshot packages lives in [`examples/earshot_example`](https://github.com/4rthurmonteiro/earshot_plugin/tree/main/examples/earshot_example).
