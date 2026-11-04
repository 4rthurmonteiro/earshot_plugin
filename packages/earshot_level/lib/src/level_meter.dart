import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/src/level_options.dart';
import 'package:earshot_level/src/level_reading.dart';

const _notImplementedMessage =
    'Not implemented yet: earshot_level 0.0.1 is an API preview. '
    'See the feature checklist at '
    'https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist';

/// {@template level_meter}
/// Turns a stream of [PcmChunk]s into a stream of [LevelReading]s.
///
/// ```dart
/// final readings = const EarshotCapture().pcm().transform(LevelMeter());
/// ```
/// {@endtemplate}
class LevelMeter extends StreamTransformerBase<PcmChunk, LevelReading> {
  /// {@macro level_meter}
  const new({this.options = const LevelOptions()});

  /// How the meter measures sound.
  final LevelOptions options;

  /// Not implemented in 0.0.1: the returned stream errors with an
  /// [UnimplementedError].
  @override
  Stream<LevelReading> bind(Stream<PcmChunk> stream) =>
      Stream.error(UnimplementedError(_notImplementedMessage));
}
