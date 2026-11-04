# earshot_capture example

```dart
import 'package:earshot_capture/earshot_capture.dart';

final status = await const MicrophonePermission().status(); // never prompts
if (status != MicrophonePermissionStatus.granted) {
  await const MicrophonePermission().request();
}

final subscription = const EarshotCapture().pcm().listen((chunk) {
  // chunk.samples is float32 mono PCM at 16 kHz.
});
await subscription.cancel(); // closes the microphone
```

A complete Flutter app that uses the earshot packages lives in [`examples/earshot_example`](https://github.com/4rthurmonteiro/earshot_plugin/tree/main/examples/earshot_example).
