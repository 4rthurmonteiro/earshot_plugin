/// The pure Dart platform interface for `earshot_capture`.
///
/// Platform implementations extend [EarshotCapturePlatform]. Apps should
/// depend on `earshot_capture` instead of this package.
library;

import 'package:earshot_capture_platform_interface/src/earshot_capture_platform.dart';

export 'src/capture_config.dart';
export 'src/capture_state.dart';
export 'src/earshot_capture_platform.dart';
export 'src/microphone_permission_status.dart';
export 'src/not_implemented.dart';
export 'src/pcm_chunk.dart';
export 'src/sample_rate.dart';
export 'src/unsupported_earshot_capture.dart';
