import 'package:meta/meta.dart';

/// Why a classifier stream failed.
///
/// New values may be added in a minor version. When you switch on this
/// enum, add a wildcard (`_`) case so that your code keeps compiling.
enum ClassifierErrorCode {
  /// The backend is not available on this platform or OS version, for
  /// example the `apple` backend on Android.
  unsupported,

  /// The backend could not load its model, or failed while classifying.
  modelUnavailable,

  /// Any other failure.
  unknown,
}

/// {@template classifier_exception}
/// An error delivered by a classifier stream.
///
/// Microphone failures are not classifier errors: they arrive as the
/// `CaptureException` that capture delivered.
/// {@endtemplate}
@immutable
class ClassifierException implements Exception {
  /// {@macro classifier_exception}
  const new(this.code, [this.message]);

  /// Why the stream failed.
  final ClassifierErrorCode code;

  /// A human-readable description, for logs. Not localized.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassifierException &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => message == null
      ? 'ClassifierException(${code.name})'
      : 'ClassifierException(${code.name}, $message)';
}
