/// On-device sound classification for Flutter.
///
/// Use [EarshotClassifier] to get a stream of [SoundDetection]s, each with
/// its [SoundGroup] and, when the label maps to one, its [EarshotSound].
///
/// earshot is informational and is not a certified detector. Never rely on
/// it for safety, including smoke and carbon monoxide alarms.
library;

import 'package:earshot_classifier/src/earshot_classifier.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

export 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart'
    show
        ClassifierBackend,
        ClassifierErrorCode,
        ClassifierException,
        EarshotSound,
        SoundDetection,
        SoundGroup,
        SoundVocabulary;

export 'src/classifier_options.dart';
export 'src/earshot_classifier.dart' show EarshotClassifier;
export 'src/smoothing.dart';
