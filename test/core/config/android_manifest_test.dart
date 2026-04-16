import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android main manifest declares internet permission', () async {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final content = await manifest.readAsString();
    expect(content, contains('android.permission.INTERNET'));
    expect(
      content,
      contains('android.permission.BIND_ACCESSIBILITY_SERVICE'),
    );
    expect(content, contains('DriverAccessibilityService'));
  });
}
