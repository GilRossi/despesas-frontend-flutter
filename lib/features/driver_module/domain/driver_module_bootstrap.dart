class DriverModuleBootstrap {
  const DriverModuleBootstrap({
    required this.moduleKey,
    required this.spaceId,
    required this.targetCity,
    required this.targetState,
    required this.targetCountry,
    required this.providers,
  });

  final String moduleKey;
  final int spaceId;
  final String targetCity;
  final String targetState;
  final String targetCountry;
  final List<DriverModuleProvider> providers;

  factory DriverModuleBootstrap.fromJson(Map<String, dynamic> json) {
    return DriverModuleBootstrap(
      moduleKey: json['moduleKey'] as String? ?? 'DRIVER',
      spaceId: _toInt(json['spaceId']),
      targetCity: json['targetCity'] as String? ?? '',
      targetState: json['targetState'] as String? ?? '',
      targetCountry: json['targetCountry'] as String? ?? '',
      providers: (json['providers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DriverModuleProvider.fromJson)
          .toList(),
    );
  }
}

class DriverModuleProvider {
  const DriverModuleProvider({
    required this.key,
    required this.label,
    required this.category,
  });

  final String key;
  final String label;
  final String category;

  factory DriverModuleProvider.fromJson(Map<String, dynamic> json) {
    return DriverModuleProvider(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}
