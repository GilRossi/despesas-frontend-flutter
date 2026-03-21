import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment({required this.name, required this.apiBaseUrl});

  final String name;
  final Uri apiBaseUrl;

  factory AppEnvironment.fromEnvironment() {
    final name = const String.fromEnvironment('APP_ENV', defaultValue: 'local');
    final configuredBaseUrl = const String.fromEnvironment('API_BASE_URL');

    return AppEnvironment(
      name: name,
      apiBaseUrl: Uri.parse(
        configuredBaseUrl.isEmpty ? _defaultBaseUrl() : configuredBaseUrl,
      ),
    );
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      _ => 'http://127.0.0.1:8080',
    };
  }
}
