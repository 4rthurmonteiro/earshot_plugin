import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/src/yamnet/resampler.dart';
import 'package:meta/meta.dart';

/// One YAMNet input window: 15,600 samples at 16 kHz.
@internal
typedef YamnetWindow = ({Float32List samples, Duration timestamp});

/// {@template yamnet_framer}
/// Cuts PCM into the overlapping windows YAMNet classifies.
///
/// Each window holds [windowLength] samples at [sampleRate] (0.975 s) and
/// starts [hopLength] samples (0.4875 s, a 50% hop) after the previous one.
/// PCM at 44.1 or 48 kHz is resampled to 16 kHz first.
///
/// A window's timestamp is the timestamp of the first chunk plus the time
/// of its first sample, so gaps in the PCM are not reflected.
/// {@endtemplate}
@internal
class YamnetFramer {
  /// {@macro yamnet_framer}
  new();

  /// The rate YAMNet expects, in Hz.
  static const sampleRate = 16000;

  /// The number of samples in a window.
  static const windowLength = 15600;

  /// The number of samples between the starts of two windows.
  static const hopLength = 7800;

  static const int _hopMicroseconds = hopLength * 1000000 ~/ sampleRate;

  final Float32List _buffer = Float32List(windowLength);
  int _filled = 0;
  int _windows = 0;
  Duration? _start;
  SampleRate? _inputRate;
  Resampler? _resampler;

  /// Adds [chunk] and returns the windows it completes, oldest first.
  List<YamnetWindow> add(PcmChunk chunk) {
    _start ??= chunk.timestamp;
    if (chunk.sampleRate != _inputRate) {
      _inputRate = chunk.sampleRate;
      _resampler = chunk.sampleRate.hz == sampleRate
          ? null
          : Resampler(inputRate: chunk.sampleRate.hz, outputRate: sampleRate);
    }
    final samples = _resampler?.process(chunk.samples) ?? chunk.samples;
    final windows = <YamnetWindow>[];
    var read = 0;
    while (read < samples.length) {
      final count = math.min(windowLength - _filled, samples.length - read);
      _buffer.setRange(_filled, _filled + count, samples, read);
      _filled += count;
      read += count;
      if (_filled == windowLength) {
        windows.add((
          samples: Float32List.fromList(_buffer),
          timestamp:
              _start! + Duration(microseconds: _windows * _hopMicroseconds),
        ));
        _windows++;
        _buffer.setRange(0, windowLength - hopLength, _buffer, hopLength);
        _filled = windowLength - hopLength;
      }
    }
    return windows;
  }
}
