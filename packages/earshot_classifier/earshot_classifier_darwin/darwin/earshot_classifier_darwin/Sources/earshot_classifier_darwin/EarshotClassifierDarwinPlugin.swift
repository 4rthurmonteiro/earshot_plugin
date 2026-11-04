#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The iOS and macOS host side of earshot_classifier.
///
/// A stub in 0.0.1. The SoundAnalysis backend and its Pigeon API land in a
/// later version.
public class EarshotClassifierDarwinPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {}
}
