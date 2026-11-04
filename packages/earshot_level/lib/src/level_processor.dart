import 'dart:math' as math;

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_level/src/dsp/rolling_leq.dart';
import 'package:earshot_level/src/dsp/time_weighting.dart';
import 'package:earshot_level/src/dsp/weighting_filter.dart';
import 'package:earshot_level/src/level_options.dart';
import 'package:earshot_level/src/level_reading.dart';

/// {@template level_processor}
/// The synchronous state machine behind `LevelMeter`: turns [PcmChunk]s into
/// [LevelReading]s, one per non-empty chunk.
///
/// Internal to `earshot_level`.
/// {@endtemplate}
class LevelProcessor {
  /// {@macro level_processor}
  new(this.options);

  /// How the levels are measured.
  final LevelOptions options;

  /// The length of a rolling Leq bin, in seconds.
  static const _binSeconds = 0.01;

  final RollingLeq _leq1s = RollingLeq(100);
  final RollingLeq _leq60s = RollingLeq(6000);

  int? _sampleRate;
  late WeightingFilter _filter;
  late TimeWeighting _timeWeighting;
  double _meanSquare = 0;
  int _binSamples = 0;

  double _binSum = 0;
  int _binFilled = 0;

  double _sessionEnergy = 0;
  double _sessionSeconds = 0;

  /// Measures [chunk] and returns the reading at its last sample, or `null`
  /// if the chunk has no samples.
  LevelReading? add(PcmChunk chunk) {
    final samples = chunk.samples;
    if (samples.isEmpty) return null;
    final sampleRate = chunk.sampleRate.hz;
    if (sampleRate != _sampleRate) _configure(sampleRate);

    final filter = _filter;
    final timeWeighting = _timeWeighting;
    var chunkSum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final y = filter.process(samples[i]);
      final square = y * y;
      chunkSum += square;
      timeWeighting.add(square);
      _binSum += square;
      if (++_binFilled == _binSamples) {
        final binMeanSquare = _binSum / _binSamples;
        _leq1s.addBin(binMeanSquare);
        _leq60s.addBin(binMeanSquare);
        _binSum = 0;
        _binFilled = 0;
      }
    }
    _meanSquare = timeWeighting.meanSquare;
    _sessionEnergy += chunkSum / sampleRate;
    _sessionSeconds += samples.length / sampleRate;

    final partialMeanSquare = _binFilled == 0 ? 0.0 : _binSum / _binFilled;
    final partialFraction = _binFilled / _binSamples;
    final duration = Duration(
      microseconds:
          (samples.length * Duration.microsecondsPerSecond / sampleRate)
              .round(),
    );
    return LevelReading(
      db: _decibels(_meanSquare),
      leq: _decibels(_sessionEnergy / _sessionSeconds),
      leq1s: _decibels(
        _leq1s.meanSquare(
          partialMeanSquare: partialMeanSquare,
          partialFraction: partialFraction,
        ),
      ),
      leq60s: _decibels(
        _leq60s.meanSquare(
          partialMeanSquare: partialMeanSquare,
          partialFraction: partialFraction,
        ),
      ),
      weighting: options.weighting,
      timestamp: chunk.timestamp + duration,
    );
  }

  /// Designs the filters for [sampleRate].
  ///
  /// The time-weighted level, the session Leq and the completed rolling Leq
  /// bins carry over. The filter state starts from silence, and the partial
  /// rolling Leq bin (under 10 ms of audio) is dropped.
  void _configure(int sampleRate) {
    _sampleRate = sampleRate;
    _filter = WeightingFilter(options.weighting, sampleRate);
    _timeWeighting = TimeWeighting(options.response, sampleRate)
      ..meanSquare = _meanSquare;
    _binSamples = (sampleRate * _binSeconds).round();
    _binSum = 0;
    _binFilled = 0;
  }

  /// Converts a mean square to decibels relative to a full-scale sine, with
  /// the floor and the calibration applied.
  double _decibels(double meanSquare) {
    final db = 10 * math.log(2 * meanSquare) / math.ln10;
    return math.max(db, LevelReading.floorDb) + options.calibration.offsetDb;
  }
}
