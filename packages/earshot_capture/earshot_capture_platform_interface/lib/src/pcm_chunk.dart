import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/src/sample_rate.dart';
import 'package:meta/meta.dart';

/// {@template pcm_chunk}
/// A chunk of mono PCM audio delivered by the microphone.
/// {@endtemplate}
@immutable
class PcmChunk {
  /// {@macro pcm_chunk}
  const new({
    required this.samples,
    required this.sampleRate,
    required this.timestamp,
  });

  /// The float32 mono samples, nominally in the range -1 to 1.
  final Float32List samples;

  /// The rate the [samples] were captured at.
  final SampleRate sampleRate;

  /// The time of the first sample, relative to the start of capture.
  ///
  /// The first chunk of every subscription has a timestamp of zero. After an
  /// interruption, the timestamps jump forward by the length of the gap.
  final Duration timestamp;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PcmChunk ||
        other.sampleRate != sampleRate ||
        other.timestamp != timestamp ||
        other.samples.length != samples.length) {
      return false;
    }
    for (var i = 0; i < samples.length; i++) {
      if (other.samples[i] != samples[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(samples), sampleRate, timestamp);

  @override
  String toString() =>
      'PcmChunk(samples: ${samples.length}, sampleRate: $sampleRate, '
      'timestamp: $timestamp)';
}
