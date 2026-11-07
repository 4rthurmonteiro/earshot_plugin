import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'earshot_classifier_darwin',
    swiftOut: 'darwin/earshot_classifier_darwin/Sources/earshot_classifier_darwin/Messages.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
/// The configuration of one classification session.
class ClassifierSessionMessage {
  new({required this.sessionId, required this.minConfidence});

  /// Chosen by Dart, unique while the session runs. Every event of the
  /// session carries it.
  int sessionId;

  /// The host drops classifications scored below this confidence.
  double minConfidence;
}

/// One chunk of PCM for a session to analyze.
class ClassifierPcmMessage {
  new({
    required this.sessionId,
    required this.sampleRate,
    required this.timestampMicros,
    required this.samples,
  });

  /// The session that analyzes this chunk.
  int sessionId;

  /// The rate of [samples], in hertz.
  int sampleRate;

  /// The time of the first sample since capture started, in microseconds.
  /// A jump from the end of the previous chunk marks an interruption.
  int timestampMicros;

  /// Mono float32 samples, as little-endian bytes. Pigeon has no
  /// `Float32List`.
  Uint8List samples;
}

/// One label scored by SoundAnalysis.
class ClassificationMessage {
  new({required this.identifier, required this.confidence});

  /// The SoundAnalysis identifier, such as `dog_bark`.
  String identifier;

  /// The confidence, from 0 to 1.
  double confidence;
}

/// What the host reports for one session: either the classifications of one
/// analysis window, or the error that ended the session.
class ClassifierEventMessage {
  new({
    required this.sessionId,
    required this.timestampMicros,
    required this.classifications,
    this.errorCode,
    this.errorMessage,
  });

  /// The session this event belongs to.
  int sessionId;

  /// The start of the analysis window, on the clock of the PCM timestamps,
  /// in microseconds.
  int timestampMicros;

  /// The classifications at or above the session's minimum confidence.
  List<ClassificationMessage> classifications;

  /// When set, the session failed and has stopped: a `CaptureErrorCode`
  /// name, such as `audioUnavailable`.
  String? errorCode;

  /// A human-readable description of [errorCode].
  String? errorMessage;
}

/// The calls Dart makes to the iOS and macOS host.
@HostApi()
abstract class EarshotClassifierHostApi {
  /// Whether SoundAnalysis can run on this OS. Never prompts the user.
  bool isAvailable();

  /// Starts the session [session]. It classifies the PCM sent with
  /// [analyze], and its events arrive on `classifierEvents`.
  void startSession(ClassifierSessionMessage session);

  /// Queues [pcm] for its session's analyzer. Does nothing if the session is
  /// not running.
  void analyze(ClassifierPcmMessage pcm);

  /// Stops the session [sessionId]. Does nothing if it is not running.
  void stopSession(int sessionId);
}

/// The stream the iOS and macOS host sends to Dart.
@EventChannelApi()
abstract class EarshotClassifierEventApi {
  /// The events of every running session.
  ClassifierEventMessage classifierEvents();
}
