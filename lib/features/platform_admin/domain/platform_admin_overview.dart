class PlatformAdminOverview {
  const PlatformAdminOverview({
    required this.totalSpaces,
    required this.activeSpaces,
    required this.totalUsers,
    required this.totalPlatformAdmins,
    required this.modules,
    required this.actuator,
  });

  final int totalSpaces;
  final int activeSpaces;
  final int totalUsers;
  final int totalPlatformAdmins;
  final List<PlatformAdminModuleUsage> modules;
  final PlatformAdminActuatorExposure actuator;

  factory PlatformAdminOverview.fromJson(Map<String, dynamic> json) {
    return PlatformAdminOverview(
      totalSpaces: _toInt(json['totalSpaces']),
      activeSpaces: _toInt(json['activeSpaces']),
      totalUsers: _toInt(json['totalUsers']),
      totalPlatformAdmins: _toInt(json['totalPlatformAdmins']),
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlatformAdminModuleUsage.fromJson)
          .toList(),
      actuator: PlatformAdminActuatorExposure.fromJson(
        json['actuator'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PlatformAdminModuleUsage {
  const PlatformAdminModuleUsage({
    required this.key,
    required this.enabledSpaces,
    required this.disabledSpaces,
    required this.mandatory,
  });

  final String key;
  final int enabledSpaces;
  final int disabledSpaces;
  final bool mandatory;

  factory PlatformAdminModuleUsage.fromJson(Map<String, dynamic> json) {
    return PlatformAdminModuleUsage(
      key: json['key'] as String? ?? '',
      enabledSpaces: _toInt(json['enabledSpaces']),
      disabledSpaces: _toInt(json['disabledSpaces']),
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}

class PlatformAdminActuatorExposure {
  const PlatformAdminActuatorExposure({
    required this.healthExposed,
    required this.infoExposed,
    required this.metricsExposed,
  });

  final bool healthExposed;
  final bool infoExposed;
  final bool metricsExposed;

  factory PlatformAdminActuatorExposure.fromJson(Map<String, dynamic> json) {
    return PlatformAdminActuatorExposure(
      healthExposed: json['healthExposed'] as bool? ?? false,
      infoExposed: json['infoExposed'] as bool? ?? false,
      metricsExposed: json['metricsExposed'] as bool? ?? false,
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
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
