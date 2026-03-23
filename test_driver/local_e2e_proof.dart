import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('build/local_e2e/screenshots')
    ..createSync(recursive: true);

  await integrationDriver(
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('${directory.path}/$screenshotName.png');
      file.writeAsBytesSync(screenshotBytes);
      return true;
    },
    writeResponseOnFailure: true,
  );
}
