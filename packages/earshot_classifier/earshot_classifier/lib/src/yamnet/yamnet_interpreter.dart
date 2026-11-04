import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:meta/meta.dart';

/// Runs the YAMNet model on one window of audio.
///
/// The seam between the Dart pipeline and LiteRT, so that the pipeline can
/// be tested without native libraries.
@internal
abstract interface class YamnetInterpreter {
  /// Classifies [waveform], 15,600 samples at 16 kHz, and returns the 521
  /// class scores in model output order.
  Future<Float32List> run(Float32List waveform);

  /// Releases the model and its isolate.
  Future<void> close();
}

/// Loads the YAMNet model for a classification session.
@internal
typedef YamnetInterpreterLoader = Future<YamnetInterpreter> Function();

/// The loader every YAMNet session uses. Tests replace it with a fake.
@internal
YamnetInterpreterLoader yamnetInterpreterLoader = LiteRtYamnetInterpreter.load;

/// {@template lite_rt_yamnet_interpreter}
/// A [YamnetInterpreter] backed by LiteRT through `flutter_litert`. Inference
/// runs in a background isolate through an `IsolateInterpreter`.
/// {@endtemplate}
@internal
class LiteRtYamnetInterpreter implements YamnetInterpreter {
  new _(this._interpreter, this._isolate);

  /// The asset key of the bundled `yamnet.tflite` (float32, from MediaPipe).
  static const assetKey = 'packages/earshot_classifier/assets/yamnet.tflite';

  /// The number of scores the model outputs.
  static const classCount = 521;

  /// Loads the bundled model from [bundle], [rootBundle] by default.
  static Future<YamnetInterpreter> load({AssetBundle? bundle}) async {
    final data = await (bundle ?? rootBundle).load(assetKey);
    return await fromBuffer(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Loads the model from the bytes of a `.tflite` file.
  static Future<YamnetInterpreter> fromBuffer(Uint8List model) async {
    final interpreter = Interpreter.fromBuffer(model);
    final isolate = await IsolateInterpreter.create(
      address: interpreter.address,
      debugName: 'earshot_yamnet',
    );
    return LiteRtYamnetInterpreter._(interpreter, isolate);
  }

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  bool _closed = false;

  @override
  Future<Float32List> run(Float32List waveform) async {
    final output = [List<double>.filled(classCount, 0)];
    await _isolate.run(waveform, output);
    return Float32List.fromList(output.first);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _isolate.close();
    _interpreter.close();
  }
}
