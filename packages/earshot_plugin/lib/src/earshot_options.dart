import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_level/earshot_level.dart';
import 'package:earshot_plugin/src/earshot.dart';
import 'package:meta/meta.dart';

/// {@template earshot_options}
/// What [Earshot.listen] measures and how.
/// {@endtemplate}
@immutable
class EarshotOptions {
  /// {@macro earshot_options}
  const new({
    this.capture = const CaptureConfig(),
    this.level = const LevelOptions(),
    this.classifier = const ClassifierOptions(),
  });

  /// How the microphone is captured, for the level meter and for YAMNet.
  ///
  /// Defaults to 16 kHz, the rate YAMNet runs at, so classification needs
  /// no resampling and joins any other 16 kHz capture in the app. The level
  /// meter works at every rate, but at 16 kHz it cannot measure anything
  /// above 8 kHz. Pick [SampleRate.hz48000] for a full-band level: YAMNet
  /// then resamples to 16 kHz in Dart, at some CPU cost.
  final CaptureConfig capture;

  /// How the sound level is measured, or `null` to skip level metering.
  final LevelOptions? level;

  /// How sounds are classified, or `null` to skip classification.
  final ClassifierOptions? classifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarshotOptions &&
          other.capture == capture &&
          other.level == level &&
          other.classifier == classifier;

  @override
  int get hashCode => Object.hash(capture, level, classifier);

  @override
  String toString() =>
      'EarshotOptions(capture: $capture, level: $level, '
      'classifier: $classifier)';
}
