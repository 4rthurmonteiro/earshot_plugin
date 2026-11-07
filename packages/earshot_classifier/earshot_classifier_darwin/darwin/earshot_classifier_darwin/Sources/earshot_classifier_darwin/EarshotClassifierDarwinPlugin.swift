#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The iOS and macOS host side of earshot_classifier: Apple SoundAnalysis on
/// the PCM that earshot_capture delivers to Dart (ADR 0018).
public class EarshotClassifierDarwinPlugin: NSObject, FlutterPlugin, EarshotClassifierHostApi {
  private let classifier = SoundClassifier()
  private let eventHandler = ClassifierEventsHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar's `messenger` is a method on iOS and a property on macOS.
    #if os(iOS)
      let messenger = registrar.messenger()
    #elseif os(macOS)
      let messenger = registrar.messenger
    #endif

    let instance = EarshotClassifierDarwinPlugin()
    EarshotClassifierHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
    ClassifierEventsStreamHandler.register(with: messenger, streamHandler: instance.eventHandler)
    registrar.publish(instance)
  }

  override init() {
    super.init()
    classifier.onEvent = { [eventHandler] event in
      eventHandler.sink?.success(event)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    classifier.stopAll()
  }

  /// Never prompts the user.
  func isAvailable() throws -> Bool {
    SoundClassifier.isAvailable()
  }

  func startSession(session: ClassifierSessionMessage) throws {
    try classifier.start(id: session.sessionId, minConfidence: session.minConfidence)
  }

  func analyze(pcm: ClassifierPcmMessage) throws {
    classifier.analyze(
      id: pcm.sessionId, sampleRate: pcm.sampleRate, timestampMicros: pcm.timestampMicros,
      samples: pcm.samples.data)
  }

  func stopSession(sessionId: Int64) throws {
    classifier.stop(id: sessionId)
  }
}

/// Holds the sink of the event channel while Dart listens.
private final class ClassifierEventsHandler: ClassifierEventsStreamHandler {
  var sink: PigeonEventSink<ClassifierEventMessage>?

  override func onListen(
    withArguments arguments: Any?, sink: PigeonEventSink<ClassifierEventMessage>
  ) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }
}
