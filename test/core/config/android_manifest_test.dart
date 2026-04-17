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
    expect(content, contains('com.ubercab.driver'));
    expect(content, contains('com.app99.driver'));
    expect(content, contains('br.com.ifood.driver.app'));
  });

  test('driver accessibility config retrieves interactive windows', () async {
    final config = File(
      'android/app/src/main/res/xml/driver_accessibility_service_config.xml',
    );
    final content = await config.readAsString();
    expect(
      content,
      contains('typeWindowStateChanged|typeWindowContentChanged'),
    );
    expect(content, contains('flagRetrieveInteractiveWindows'));
    expect(content, contains('android:canRetrieveWindowContent="true"'));
  });
}
