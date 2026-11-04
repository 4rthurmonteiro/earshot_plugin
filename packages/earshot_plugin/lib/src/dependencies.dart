import 'package:earshot_capture/earshot_capture.dart';
import 'package:earshot_classifier/earshot_classifier.dart';
import 'package:meta/meta.dart';

/// Builds the classifier an `Earshot` session uses.
@internal
typedef EarshotClassifierFactory = EarshotClassifier Function(
  ClassifierOptions options,
);

/// The capture every `Earshot` session uses. Tests replace it with a mock.
@internal
EarshotCapture earshotCapture = const EarshotCapture();

/// Builds the classifier of every `Earshot` session. Tests replace it with a
/// factory that returns a mock.
@internal
EarshotClassifierFactory earshotClassifierFactory = defaultClassifierFactory;

/// Builds an [EarshotClassifier] with [options].
@internal
EarshotClassifier defaultClassifierFactory(ClassifierOptions options) =>
    EarshotClassifier(options: options);
