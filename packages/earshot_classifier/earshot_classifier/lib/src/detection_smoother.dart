import 'package:earshot_classifier/src/smoothing.dart';
import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';
import 'package:meta/meta.dart';

/// {@template detection_smoother}
/// Applies [Smoothing] to raw detections, one stream at a time.
///
/// A detection counts as a hit for its sound, or for its raw label when it
/// maps to no sound. It is confirmed when its key has at least
/// [Smoothing.hits] hits whose timestamps lie within [Smoothing.window] of
/// it. Several detections with the same key and timestamp, from the same
/// analysis window, count as one hit and are confirmed at most once.
///
/// Once confirmed, a sound keeps being reported for every window in which it
/// is still detected often enough.
/// {@endtemplate}
@internal
class DetectionSmoother {
  /// {@macro detection_smoother}
  new(this.smoothing);

  /// How detections are confirmed.
  final Smoothing smoothing;

  final Map<Object, List<Duration>> _hits = {};

  /// Records [detection] and returns it if it is confirmed, or `null`.
  SoundDetection? add(SoundDetection detection) {
    final hits = _hits.putIfAbsent(
      detection.sound ?? detection.rawLabel,
      () => [],
    );
    final timestamp = detection.timestamp;
    if (hits.isNotEmpty && hits.last == timestamp) return null;
    hits
      ..add(timestamp)
      ..removeWhere((hit) => timestamp - hit > smoothing.window);
    return hits.length >= smoothing.hits ? detection : null;
  }
}
