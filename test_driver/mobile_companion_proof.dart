import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final screenshotsDirectory = Directory(
    Platform.environment['PROOF_SCREENSHOTS_DIR'] ??
        'build/mobile_e2e/screenshots',
  )..createSync(recursive: true);
  final outputDirectory =
      Platform.environment['PROOF_OUTPUT_DIR'] ?? 'build/mobile_e2e';
  final outputName =
      Platform.environment['PROOF_OUTPUT_NAME'] ??
      'mobile_companion_proof_response';

  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          final file = File('${screenshotsDirectory.path}/$screenshotName.png');
          file.writeAsBytesSync(screenshotBytes);
          return true;
        },
    responseDataCallback: (data) async {
      await writeResponseData(
        data,
        testOutputFilename: outputName,
        destinationDirectory: outputDirectory,
      );
    },
    writeResponseOnFailure: true,
  );
}
