/// On-device ambient listening for Flutter: how loud it is and what is
/// sounding, in one stream.
///
/// Start with [Earshot]. Audio never leaves the device.
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including smoke and carbon monoxide alarms.
library;

import 'package:earshot_plugin/src/earshot.dart';

export 'package:earshot_capture/earshot_capture.dart';
export 'package:earshot_classifier/earshot_classifier.dart';
export 'package:earshot_level/earshot_level.dart';

export 'src/earshot.dart';
export 'src/earshot_event.dart';
export 'src/earshot_exception.dart';
export 'src/earshot_options.dart';
