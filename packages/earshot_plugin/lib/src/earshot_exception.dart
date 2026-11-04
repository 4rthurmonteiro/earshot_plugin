import 'package:meta/meta.dart';

/// Why an earshot stream failed.
enum EarshotErrorCode {
  /// The user denied microphone access, or has not granted it yet.
  permissionDenied,

  /// The feature is not available on this platform or OS version, for
  /// example the `apple` classifier backend on Android.
  unsupported,

  /// The microphone could not be opened, or stopped delivering audio and
  /// could not be recovered. For example, another app holds it.
  audioUnavailable,

  /// The microphone is already capturing at a different sample rate.
  ///
  /// earshot shares one microphone session between every consumer in the
  /// app, so concurrent consumers must use the same sample rate.
  sampleRateConflict,

  /// The sound classifier could not load its model, or failed while
  /// classifying.
  modelUnavailable,

  /// Any other failure.
  unknown,
}

/// {@template earshot_exception}
/// An error delivered by an earshot stream.
///
/// An earshot stream ends after its first error.
/// {@endtemplate}
@immutable
class EarshotException implements Exception {
  /// {@macro earshot_exception}
  const new(this.code, [this.message, this.cause]);

  /// Why the stream failed.
  final EarshotErrorCode code;

  /// A human-readable description, for logs. Not localized.
  final String? message;

  /// The error this exception was mapped from, such as a `CaptureException`,
  /// or `null` if earshot raised it itself. For logs and debugging: its type
  /// is not part of the API and may change.
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarshotException &&
          other.code == code &&
          other.message == message &&
          other.cause == cause;

  @override
  int get hashCode => Object.hash(code, message, cause);

  @override
  String toString() => message == null
      ? 'EarshotException(${code.name})'
      : 'EarshotException(${code.name}, $message)';
}
