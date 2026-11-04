import 'package:earshot_plugin/src/earshot_event.dart';
import 'package:earshot_plugin/src/earshot_exception.dart';
import 'package:earshot_plugin/src/earshot_options.dart';

const _notImplementedMessage =
    'Not implemented yet: earshot_plugin 0.0.1 is an API preview. '
    'See the feature checklist at '
    'https://github.com/4rthurmonteiro/earshot_plugin#feature-checklist';

/// {@template earshot}
/// Listens to the microphone and reports how loud it is and what is
/// sounding, on-device.
///
/// Audio never leaves the device and is never written to disk. earshot is
/// informational and is not a certified detector.
/// {@endtemplate}
class Earshot {
  /// {@macro earshot}
  const new();

  /// Starts listening with [options] and returns what earshot hears.
  ///
  /// Each call to `listen()` on the returned stream starts its own session,
  /// and cancelling the subscription stops it. The stream never throws
  /// synchronously: failures are delivered as [EarshotException] stream
  /// errors.
  ///
  /// Not implemented in 0.0.1: the stream errors with an
  /// [UnimplementedError].
  Stream<EarshotEvent> listen({
    EarshotOptions options = const EarshotOptions(),
  }) => Stream.error(UnimplementedError(_notImplementedMessage));
}
