import AVFoundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The iOS and macOS host side of earshot_classifier: Apple SoundAnalysis.
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
    try classifier.start(
      id: session.sessionId, minConfidence: session.minConfidence,
      permission: Self.microphoneGranted())
  }

  func stopSession(sessionId: Int64) throws {
    classifier.stop(id: sessionId)
  }

  /// Reads the record permission without prompting the user. Classification
  /// never prompts: apps request access with earshot_capture first.
  private static func microphoneGranted() -> Bool {
    #if os(iOS)
      if #available(iOS 17.0, *) {
        return AVAudioApplication.shared.recordPermission == .granted
      }
      return AVAudioSession.sharedInstance().recordPermission == .granted
    #elseif os(macOS)
      return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    #endif
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
