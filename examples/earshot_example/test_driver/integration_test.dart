import 'package:integration_test/integration_test_driver.dart';

/// Runs the integration tests and writes the data they report to
/// `build/yamnet_benchmark.json`.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data != null) {
      await writeResponseData(data, testOutputFilename: 'yamnet_benchmark');
    }
  },
);
