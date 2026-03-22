class AppEnvironment {
  const AppEnvironment({required this.name, required this.apiBaseUrl});

  final String name;
  final Uri apiBaseUrl;

  factory AppEnvironment.fromEnvironment() {
    final name = const String.fromEnvironment('APP_ENV', defaultValue: 'local');
    final configuredBaseUrl = const String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL ausente. Use --dart-define=API_BASE_URL=<url> para iniciar o app.',
      );
    }

    final parsedBaseUrl = Uri.parse(configuredBaseUrl);
    if (!parsedBaseUrl.hasScheme || parsedBaseUrl.host.isEmpty) {
      throw FormatException(
        'API_BASE_URL invalida. Informe uma URL absoluta, por exemplo http://127.0.0.1:8080.',
        configuredBaseUrl,
      );
    }

    return AppEnvironment(
      name: name,
      apiBaseUrl: parsedBaseUrl,
    );
  }
}
