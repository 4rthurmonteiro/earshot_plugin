import 'package:meta/meta.dart';

/// Why an earshot stream failed.
enum EarshotErrorCode {
  /// The user denied microphone access.
  permissionDenied,

  /// The feature is not available on this platform or OS version.
  unsupported,

  /// The microphone could not be opened, for example because another app is
  /// using it.
  audioUnavailable,

  /// The sound classification model could not be loaded.
  modelUnavailable,

  /// Any other failure.
  unknown,
}

/// {@template earshot_exception}
/// An error delivered by an earshot stream.
/// {@endtemplate}
@immutable
class EarshotException implements Exception {
  /// {@macro earshot_exception}
  const new(this.code, [this.message]);

  /// Why the stream failed.
  final EarshotErrorCode code;

  /// A human-readable description, for logs. Not localized.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarshotException &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => message == null
      ? 'EarshotException(${code.name})'
      : 'EarshotException(${code.name}, $message)';
}
