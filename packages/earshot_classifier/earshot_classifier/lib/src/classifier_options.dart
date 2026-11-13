import 'package:earshot_classifier/src/smoothing.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:meta/meta.dart';

/// {@template classifier_options}
/// How the classifier recognizes sounds.
/// {@endtemplate}
@immutable
class ClassifierOptions {
  /// {@macro classifier_options}
  ///
  /// [minConfidence] must be between 0 and 1. Debug builds check it here;
  /// in every build, `EarshotClassifier` streams fail with an
  /// [ArgumentError] when it is out of range.
  const new({
    this.backend,
    this.minConfidence = 0.5,
    this.smoothing = const Smoothing(),
  }) : assert(
         minConfidence >= 0 && minConfidence <= 1,
         'minConfidence must be between 0 and 1',
       );

  /// The engine that classifies sounds, or `null`, the default, to pick the
  /// best one for the platform: [ClassifierBackend.apple] on iOS and macOS
  /// when it is available, and [ClassifierBackend.yamnet] otherwise.
  final ClassifierBackend? backend;

  /// Detections below this confidence are dropped. Defaults to 0.5.
  final double minConfidence;

  /// How detections are confirmed before they are reported.
  final Smoothing smoothing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassifierOptions &&
          other.backend == backend &&
          other.minConfidence == minConfidence &&
          other.smoothing == smoothing;

  @override
  int get hashCode => Object.hash(backend, minConfidence, smoothing);

  @override
  String toString() =>
      'ClassifierOptions(backend: $backend, minConfidence: $minConfidence, '
      'smoothing: $smoothing)';
}
