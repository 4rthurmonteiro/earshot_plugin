/// On-device microphone capture for Flutter.
///
/// Use [EarshotCapture] to stream PCM and [MicrophonePermission] to read or
/// request the permission.
library;

import 'package:earshot_capture/src/earshot_capture.dart';
import 'package:earshot_capture/src/microphone_permission.dart';

export 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart'
    show
        CaptureConfig,
        CaptureErrorCode,
        CaptureException,
        CaptureState,
        MicrophonePermissionStatus,
        PcmChunk,
        SampleRate;

export 'src/earshot_capture.dart';
export 'src/microphone_permission.dart';
