import 'package:meta/meta.dart';

/// Why a capture stream failed.
enum CaptureErrorCode {
  /// The user denied microphone access, or has not granted it yet.
  permissionDenied,

  /// The microphone could not be opened, or stopped delivering audio and
  /// could not be recovered. For example, another app holds it.
  audioUnavailable,

  /// Capture is already running at a different sample rate.
  ///
  /// Concurrent subscriptions share one microphone session, so they must
  /// request the same `SampleRate`.
  sampleRateConflict,

  /// Any other failure.
  unknown,
}

/// {@template capture_exception}
/// An error delivered by a capture stream.
/// {@endtemplate}
@immutable
class CaptureException implements Exception {
  /// {@macro capture_exception}
  const new(this.code, [this.message]);

  /// Why the stream failed.
  final CaptureErrorCode code;

  /// A human-readable description, for logs. Not localized.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptureException &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => message == null
      ? 'CaptureException(${code.name})'
      : 'CaptureException(${code.name}, $message)';
}
