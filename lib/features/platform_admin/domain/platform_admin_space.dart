class PlatformAdminSpace {
  const PlatformAdminSpace({
    required this.spaceId,
    required this.spaceName,
    required this.createdAt,
    required this.updatedAt,
    required this.activeMembersCount,
    required this.owner,
    required this.modules,
  });

  final int spaceId;
  final String spaceName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int activeMembersCount;
  final PlatformAdminSpaceOwner? owner;
  final List<PlatformAdminSpaceModule> modules;

  factory PlatformAdminSpace.fromJson(Map<String, dynamic> json) {
    return PlatformAdminSpace(
      spaceId: _toInt(json['spaceId']),
      spaceName: json['spaceName'] as String? ?? '',
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      activeMembersCount: _toInt(json['activeMembersCount']),
      owner: json['owner'] is Map<String, dynamic>
          ? PlatformAdminSpaceOwner.fromJson(
              json['owner'] as Map<String, dynamic>,
            )
          : null,
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlatformAdminSpaceModule.fromJson)
          .toList(),
    );
  }
}

class PlatformAdminSpaceOwner {
  const PlatformAdminSpaceOwner({
    required this.userId,
    required this.name,
    required this.email,
  });

  final int userId;
  final String name;
  final String email;

  factory PlatformAdminSpaceOwner.fromJson(Map<String, dynamic> json) {
    return PlatformAdminSpaceOwner(
      userId: _toInt(json['userId']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class PlatformAdminSpaceModule {
  const PlatformAdminSpaceModule({
    required this.key,
    required this.enabled,
    required this.mandatory,
  });

  final String key;
  final bool enabled;
  final bool mandatory;

  factory PlatformAdminSpaceModule.fromJson(Map<String, dynamic> json) {
    return PlatformAdminSpaceModule(
      key: json['key'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      mandatory: json['mandatory'] as bool? ?? false,
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

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
