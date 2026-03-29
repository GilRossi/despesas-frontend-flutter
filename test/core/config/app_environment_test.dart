import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('constructor stores the configured environment values', () {
    final environment = AppEnvironment(
      name: 'local',
      apiBaseUrl: Uri.parse('http://127.0.0.1:8080'),
    );

    expect(environment.name, 'local');
    expect(environment.apiBaseUrl.host, '127.0.0.1');
  });

  test('fromEnvironment fails when API_BASE_URL is absent', () {
    expect(
      () => AppEnvironment.fromEnvironment(),
      throwsA(isA<StateError>()),
    );
  });
}
