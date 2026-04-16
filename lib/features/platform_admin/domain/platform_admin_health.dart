import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';

class PlatformAdminHealth {
  const PlatformAdminHealth({
    required this.applicationStatus,
    required this.checkedAt,
    required this.actuator,
    required this.deployment,
    required this.runtime,
    required this.jvm,
    required this.system,
    required this.info,
    required this.alerts,
  });

  final String applicationStatus;
  final DateTime? checkedAt;
  final PlatformAdminActuatorExposure actuator;
  final PlatformAdminDeploymentSnapshot deployment;
  final PlatformAdminRuntimeSnapshot runtime;
  final PlatformAdminJvmSnapshot jvm;
  final PlatformAdminSystemSnapshot system;
  final Map<String, dynamic> info;
  final List<PlatformAdminOperationalAlert> alerts;

  factory PlatformAdminHealth.fromJson(Map<String, dynamic> json) {
    return PlatformAdminHealth(
      applicationStatus: json['applicationStatus'] as String? ?? '',
      checkedAt: _toDateTime(json['checkedAt']),
      actuator: PlatformAdminActuatorExposure.fromJson(
        json['actuator'] as Map<String, dynamic>? ?? const {},
      ),
      deployment: PlatformAdminDeploymentSnapshot.fromJson(
        json['deployment'] as Map<String, dynamic>? ?? const {},
      ),
      runtime: PlatformAdminRuntimeSnapshot.fromJson(
        json['runtime'] as Map<String, dynamic>? ?? const {},
      ),
      jvm: PlatformAdminJvmSnapshot.fromJson(
        json['jvm'] as Map<String, dynamic>? ?? const {},
      ),
      system: PlatformAdminSystemSnapshot.fromJson(
        json['system'] as Map<String, dynamic>? ?? const {},
      ),
      info: (json['info'] as Map<String, dynamic>?) ?? const {},
      alerts: (json['alerts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlatformAdminOperationalAlert.fromJson)
          .toList(),
    );
  }
}

class PlatformAdminDeploymentSnapshot {
  const PlatformAdminDeploymentSnapshot({
    required this.applicationName,
    required this.artifact,
    required this.version,
    required this.builtAt,
  });

  final String applicationName;
  final String? artifact;
  final String? version;
  final DateTime? builtAt;

  factory PlatformAdminDeploymentSnapshot.fromJson(Map<String, dynamic> json) {
    return PlatformAdminDeploymentSnapshot(
      applicationName: json['applicationName'] as String? ?? '',
      artifact: json['artifact'] as String?,
      version: json['version'] as String?,
      builtAt: _toDateTime(json['builtAt']),
    );
  }
}

class PlatformAdminRuntimeSnapshot {
  const PlatformAdminRuntimeSnapshot({
    required this.livenessState,
    required this.readinessState,
    required this.startedAt,
  });

  final String livenessState;
  final String readinessState;
  final DateTime? startedAt;

  factory PlatformAdminRuntimeSnapshot.fromJson(Map<String, dynamic> json) {
    return PlatformAdminRuntimeSnapshot(
      livenessState: json['livenessState'] as String? ?? '',
      readinessState: json['readinessState'] as String? ?? '',
      startedAt: _toDateTime(json['startedAt']),
    );
  }
}

class PlatformAdminOperationalAlert {
  const PlatformAdminOperationalAlert({
    required this.code,
    required this.severity,
    required this.source,
    required this.title,
    required this.message,
  });

  final String code;
  final String severity;
  final String source;
  final String title;
  final String message;

  factory PlatformAdminOperationalAlert.fromJson(Map<String, dynamic> json) {
    return PlatformAdminOperationalAlert(
      code: json['code'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      source: json['source'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class PlatformAdminJvmSnapshot {
  const PlatformAdminJvmSnapshot({
    required this.availableProcessors,
    required this.uptimeMs,
    required this.heapUsedBytes,
    required this.heapCommittedBytes,
    required this.heapMaxBytes,
  });

  final int availableProcessors;
  final int uptimeMs;
  final int heapUsedBytes;
  final int heapCommittedBytes;
  final int heapMaxBytes;

  factory PlatformAdminJvmSnapshot.fromJson(Map<String, dynamic> json) {
    return PlatformAdminJvmSnapshot(
      availableProcessors: _toInt(json['availableProcessors']),
      uptimeMs: _toInt(json['uptimeMs']),
      heapUsedBytes: _toInt(json['heapUsedBytes']),
      heapCommittedBytes: _toInt(json['heapCommittedBytes']),
      heapMaxBytes: _toInt(json['heapMaxBytes']),
    );
  }
}

class PlatformAdminSystemSnapshot {
  const PlatformAdminSystemSnapshot({required this.systemLoadAverage});

  final double? systemLoadAverage;

  factory PlatformAdminSystemSnapshot.fromJson(Map<String, dynamic> json) {
    return PlatformAdminSystemSnapshot(
      systemLoadAverage: _toDoubleOrNull(json['systemLoadAverage']),
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

double? _toDoubleOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
