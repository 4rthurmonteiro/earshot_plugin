import 'dart:math' as math;
import 'dart:typed_data';

import 'package:earshot_capture_platform_interface/earshot_capture_platform_interface.dart';
import 'package:earshot_classifier/src/yamnet/resampler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

double _rms(Float32List samples, {int skip = 200}) {
  var sum = 0.0;
  for (var i = skip; i < samples.length - skip; i++) {
    sum += samples[i] * samples[i];
  }
  return math.sqrt(sum / (samples.length - 2 * skip));
}

int _zeroCrossings(Float32List samples) {
  var count = 0;
  for (var i = 1; i < samples.length; i++) {
    if ((samples[i - 1] < 0) != (samples[i] < 0)) count++;
  }
  return count;
}

void main() {
  group(Resampler, () {
    for (final rate in [SampleRate.hz48000, SampleRate.hz44100]) {
      group('from ${rate.hz} Hz to 16 kHz', () {
        Float32List resample(PcmChunk chunk) => Resampler(
          inputRate: rate.hz,
          outputRate: 16000,
        ).process(chunk.samples);

        test('keeps the duration, minus the filter latency', () {
          final output = resample(sineChunk(rate: rate));
          expect(output.length, inInclusiveRange(15900, 16000));
        });

        test('keeps the amplitude and frequency of a 1 kHz sine', () {
          final output = resample(sineChunk(rate: rate));
          expect(_rms(output), closeTo(0.5 / math.sqrt2, 0.005));
          // 1 kHz crosses zero 2000 times per second.
          expect(_zeroCrossings(output), closeTo(2000, 4));
        });

        test('removes content above 8 kHz', () {
          final output = resample(sineChunk(rate: rate, frequency: 12000));
          expect(_rms(output), lessThan(0.005));
        });

        test('gives the same output in chunks as in one piece', () {
          final whole = resample(sineChunk(rate: rate));
          final samples = sineChunk(rate: rate).samples;
          final resampler = Resampler(inputRate: rate.hz, outputRate: 16000);
          final chunked = <double>[];
          for (var start = 0; start < samples.length; start += 1000) {
            chunked.addAll(
              resampler.process(
                Float32List.sublistView(
                  samples,
                  start,
                  math.min(start + 1000, samples.length),
                ),
              ),
            );
          }
          expect(chunked.length, whole.length);
          for (var i = 0; i < whole.length; i++) {
            expect(chunked[i], closeTo(whole[i], 1e-6));
          }
        });
      });
    }

    test('returns nothing until enough input arrives', () {
      final resampler = Resampler(inputRate: 48000, outputRate: 16000);
      expect(resampler.process(Float32List(10)), isEmpty);
      expect(resampler.zeroCrossings, 16);
      expect(resampler.inputRate, 48000);
      expect(resampler.outputRate, 16000);
    });
  });
}
