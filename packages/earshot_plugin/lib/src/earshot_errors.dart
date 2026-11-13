import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:earshot_plugin/src/earshot_exception.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Maps an [error] delivered by capture or by the classifier to an
/// [EarshotException], keeping [error] as its cause.
///
/// - An [EarshotException] is returned as is.
/// - A [CaptureException] keeps its code.
/// - A [ClassifierException] keeps its code.
/// - A [PlatformException] whose code is the name of an [EarshotErrorCode]
///   gets that code.
/// - An [UnsupportedError], including an [UnimplementedError], is
///   [EarshotErrorCode.unsupported].
/// - Anything else is [EarshotErrorCode.modelUnavailable] if
///   [fromClassifier], because the classifier fails only when its model
///   cannot be loaded or run, and [EarshotErrorCode.unknown] otherwise.
@internal
EarshotException toEarshotException(
  Object error, {
  required bool fromClassifier,
}) {
  switch (error) {
    case EarshotException():
      return error;
    case CaptureException(:final code, :final message):
      return EarshotException(_captureCode(code), message, error);
    case ClassifierException(:final code, :final message):
      return EarshotException(_classifierCode(code), message, error);
    case PlatformException(:final code, :final message):
      final mapped = EarshotErrorCode.values.asNameMap()[code];
      if (mapped != null) return EarshotException(mapped, message, error);
    case UnsupportedError(:final message):
      return EarshotException(EarshotErrorCode.unsupported, message, error);
  }
  return EarshotException(
    fromClassifier
        ? EarshotErrorCode.modelUnavailable
        : EarshotErrorCode.unknown,
    '$error',
    error,
  );
}

EarshotErrorCode _captureCode(CaptureErrorCode code) => switch (code) {
  CaptureErrorCode.permissionDenied => EarshotErrorCode.permissionDenied,
  CaptureErrorCode.audioUnavailable => EarshotErrorCode.audioUnavailable,
  CaptureErrorCode.sampleRateConflict => EarshotErrorCode.sampleRateConflict,
  CaptureErrorCode.unknown => EarshotErrorCode.unknown,
};

EarshotErrorCode _classifierCode(ClassifierErrorCode code) => switch (code) {
  ClassifierErrorCode.unsupported => EarshotErrorCode.unsupported,
  ClassifierErrorCode.modelUnavailable => EarshotErrorCode.modelUnavailable,
  ClassifierErrorCode.unknown => EarshotErrorCode.unknown,
};
