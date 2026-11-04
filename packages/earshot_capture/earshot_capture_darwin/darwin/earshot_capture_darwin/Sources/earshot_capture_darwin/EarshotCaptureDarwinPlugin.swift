import AVFoundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The iOS and macOS host side of earshot_capture.
public class EarshotCaptureDarwinPlugin: NSObject, FlutterPlugin, EarshotCaptureHostApi {
  private let capture = AudioCapture()
  private let pcmHandler = PcmChunksHandler()
  private let stateHandler = CaptureStatesHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar's `messenger` is a method on iOS and a property on macOS.
    #if os(iOS)
      let messenger = registrar.messenger()
    #elseif os(macOS)
      let messenger = registrar.messenger
    #endif

    let instance = EarshotCaptureDarwinPlugin()
    EarshotCaptureHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
    PcmChunksStreamHandler.register(with: messenger, streamHandler: instance.pcmHandler)
    CaptureStatesStreamHandler.register(with: messenger, streamHandler: instance.stateHandler)
    registrar.publish(instance)
  }

  override init() {
    super.init()
    capture.onChunk = { [pcmHandler] samples, timestampMicros in
      pcmHandler.sink?.success(
        PcmChunkMessage(
          samples: FlutterStandardTypedData(bytes: samples), timestampMicros: timestampMicros))
    }
    capture.onState = { [stateHandler] state in
      stateHandler.sink?.success(CaptureStateEventMessage(state: state))
    }
    capture.onError = { [pcmHandler] code, message in
      pcmHandler.sink?.error(code: code, message: message, details: nil)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    capture.stop()
  }

  /// Reads the record permission. Never prompts the user.
  func microphonePermissionStatus() throws -> PermissionStatusMessage {
    #if os(iOS)
      if #available(iOS 17.0, *) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .undetermined
        }
      }
      switch AVAudioSession.sharedInstance().recordPermission {
      case .granted: return .granted
      case .denied: return .denied
      case .undetermined: return .undetermined
      @unknown default: return .undetermined
      }
    #elseif os(macOS)
      switch AVCaptureDevice.authorizationStatus(for: .audio) {
      case .authorized: return .granted
      case .denied: return .denied
      case .notDetermined: return .undetermined
      case .restricted: return .restricted
      @unknown default: return .undetermined
      }
    #endif
  }

  /// Prompts only if the user has not answered yet, then reads the status.
  func requestMicrophonePermission() async throws -> PermissionStatusMessage {
    guard try microphonePermissionStatus() == .undetermined else {
      return try microphonePermissionStatus()
    }
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      #if os(iOS)
        if #available(iOS 17.0, *) {
          AVAudioApplication.requestRecordPermission { _ in continuation.resume() }
        } else {
          AVAudioSession.sharedInstance().requestRecordPermission { _ in continuation.resume() }
        }
      #elseif os(macOS)
        AVCaptureDevice.requestAccess(for: .audio) { _ in continuation.resume() }
      #endif
    }
    return try microphonePermissionStatus()
  }

  func startCapture(config: CaptureConfigMessage) throws {
    try capture.start(
      sampleRate: Double(config.sampleRateHz), permission: microphonePermissionStatus())
  }

  func stopCapture() throws {
    capture.stop()
  }
}

/// Holds the sink of the PCM event channel while Dart listens.
private final class PcmChunksHandler: PcmChunksStreamHandler {
  var sink: PigeonEventSink<PcmChunkMessage>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<PcmChunkMessage>) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }
}

/// Holds the sink of the state event channel while Dart listens.
private final class CaptureStatesHandler: CaptureStatesStreamHandler {
  var sink: PigeonEventSink<CaptureStateEventMessage>?

  override func onListen(
    withArguments arguments: Any?, sink: PigeonEventSink<CaptureStateEventMessage>
  ) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }
}
