import 'package:meta/meta.dart';

/// {@template smoothing}
/// Filters out one-off detections: a sound is reported only after it is
/// detected [hits] times within [window].
/// {@endtemplate}
@immutable
class Smoothing {
  /// {@macro smoothing}
  ///
  /// [hits] must be at least 1.
  const new({this.hits = 2, this.window = const Duration(seconds: 2)})
    : assert(hits >= 1, 'hits must be at least 1');

  /// How many detections of the same sound confirm it. Defaults to 2.
  final int hits;

  /// The time the [hits] must fall within. Defaults to 2 seconds.
  final Duration window;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Smoothing && other.hits == hits && other.window == window;

  @override
  int get hashCode => Object.hash(hits, window);

  @override
  String toString() => 'Smoothing(hits: $hits, window: $window)';
}
