/// The pure Dart platform interface for `earshot_classifier`.
///
/// Platform implementations extend [EarshotClassifierPlatform]. Apps should
/// depend on `earshot_classifier` instead of this package.
library;

import 'package:earshot_classifier_platform_interface/src/earshot_classifier_platform.dart';

export 'src/classifier_backend.dart';
export 'src/classifier_config.dart';
export 'src/classifier_exception.dart';
export 'src/earshot_classifier_platform.dart';
export 'src/not_implemented.dart';
export 'src/sound_detection.dart';
export 'src/sound_group.dart';
export 'src/unsupported_earshot_classifier.dart';
export 'src/vocabulary/earshot_sound.dart';
export 'src/vocabulary/sound_vocabulary.dart';
