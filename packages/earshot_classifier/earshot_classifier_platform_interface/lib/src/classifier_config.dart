import 'package:earshot_classifier_platform_interface/src/earshot_classifier_platform.dart';
import 'package:meta/meta.dart';

/// {@template classifier_config}
/// What `earshot_classifier` asks a backend for when it starts
/// [EarshotClassifierPlatform.detections].
/// {@endtemplate}
@immutable
class ClassifierConfig {
  /// {@macro classifier_config}
  ///
  /// [minConfidence] must be between 0 and 1.
  const new({this.minConfidence = 0.5})
    : assert(
        minConfidence >= 0 && minConfidence <= 1,
        'minConfidence must be between 0 and 1',
      );

  /// Backends drop labels scored below this confidence. Defaults to 0.5.
  final double minConfidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassifierConfig && other.minConfidence == minConfidence;

  @override
  int get hashCode => minConfidence.hashCode;

  @override
  String toString() => 'ClassifierConfig(minConfidence: $minConfidence)';
}
