import 'dart:async';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/src/level_options.dart';
import 'package:earshot_level/src/level_processor.dart';
import 'package:earshot_level/src/level_reading.dart';

/// {@template level_meter}
/// Turns a stream of [PcmChunk]s into a stream of [LevelReading]s.
///
/// ```dart
/// final readings = const EarshotCapture().pcm().transform(LevelMeter());
/// ```
///
/// The meter emits one reading per non-empty chunk, measured at the chunk's
/// last sample, so the reading rate follows the chunk size. It applies the
/// frequency weighting, then the time weighting, as defined by IEC 61672-1,
/// and tracks the Leq of the session, of the last second and of the last
/// 60 seconds. See [LevelReading] for the decibel reference.
///
/// The weighting filters are designed for each chunk's sample rate (16, 44.1
/// or 48 kHz). At 16 kHz nothing above the 8 kHz Nyquist frequency can be
/// measured.
///
/// Each listen to the returned stream starts a new measurement session with
/// its own state and its own subscription to the PCM stream. Cancelling it
/// cancels that subscription. Errors from the PCM stream are forwarded.
///
/// Phone microphones are not measurement microphones: without a
/// [LevelOptions.calibration], readings are relative estimates.
/// {@endtemplate}
class LevelMeter extends StreamTransformerBase<PcmChunk, LevelReading> {
  /// {@macro level_meter}
  const new({this.options = const LevelOptions()});

  /// How the meter measures sound.
  final LevelOptions options;

  @override
  Stream<LevelReading> bind(Stream<PcmChunk> stream) =>
      Stream.multi((controller) {
        final processor = LevelProcessor(options);
        final subscription = stream.listen(
          (chunk) {
            final reading = processor.add(chunk);
            if (reading != null) controller.addSync(reading);
          },
          onError: controller.addErrorSync,
          onDone: controller.closeSync,
        );
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = subscription.cancel;
      });
}
