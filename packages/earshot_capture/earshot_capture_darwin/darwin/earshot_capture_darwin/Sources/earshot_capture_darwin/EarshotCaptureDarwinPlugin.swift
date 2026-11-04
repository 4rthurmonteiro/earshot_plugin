import AVFoundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The iOS and macOS host side of earshot_capture.
public class EarshotCaptureDarwinPlugin: NSObject, FlutterPlugin, EarshotCaptureHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar's `messenger` is a method on iOS and a property on macOS.
    #if os(iOS)
      let messenger = registrar.messenger()
    #elseif os(macOS)
      let messenger = registrar.messenger
    #endif

    let instance = EarshotCaptureDarwinPlugin()
    EarshotCaptureHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
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
}
