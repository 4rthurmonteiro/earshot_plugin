import 'package:earshot_example/yamnet_benchmark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Measures YAMNet on a real device (ADR 0022). Run it in profile mode:
///
/// ```sh
/// flutter drive --profile -d <device> \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/yamnet_benchmark_test.dart
/// ```
///
/// The result is written to `build/yamnet_benchmark.json`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('YAMNet window time', (tester) async {
    final result = await runYamnetBenchmark();
    binding.reportData = {'yamnet': result.toJson()};
    debugPrint('$result');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
