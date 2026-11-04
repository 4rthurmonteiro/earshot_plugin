/// Pure Dart sound level metering for earshot.
///
/// Feed the PCM from `earshot_capture` through a [LevelMeter] to get
/// [LevelReading]s in decibels.
library;

import 'package:earshot_level/src/level_meter.dart';
import 'package:earshot_level/src/level_reading.dart';

export 'src/calibration.dart';
export 'src/level_meter.dart';
export 'src/level_options.dart';
export 'src/level_reading.dart';
export 'src/response.dart';
export 'src/weighting.dart';
