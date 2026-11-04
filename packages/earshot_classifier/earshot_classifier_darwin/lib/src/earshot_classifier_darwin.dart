import 'package:earshot_classifier_platform_interface/earshot_classifier_platform_interface.dart';

/// {@template earshot_classifier_darwin}
/// The iOS and macOS implementation of [EarshotClassifierPlatform], backed by
/// the [ClassifierBackend.apple] backend (SoundAnalysis).
///
/// Not implemented yet: every method completes with an [UnimplementedError],
/// so `ClassifierBackend.auto` falls back to YAMNet on iOS and macOS. The
/// SoundAnalysis backend will implement
/// [EarshotClassifierPlatform.isAvailable] and
/// [EarshotClassifierPlatform.detections].
/// {@endtemplate}
class EarshotClassifierDarwin extends EarshotClassifierPlatform {
  /// {@macro earshot_classifier_darwin}
  new();

  /// Registers this class as the [EarshotClassifierPlatform.instance].
  static void registerWith() {
    EarshotClassifierPlatform.instance = EarshotClassifierDarwin();
  }
}
