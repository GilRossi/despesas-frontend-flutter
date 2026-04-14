import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';

class PlatformAdminHealth {
  const PlatformAdminHealth({
    required this.applicationStatus,
    required this.checkedAt,
    required this.actuator,
    required this.jvm,
    required this.system,
    required this.info,
  });

  final String applicationStatus;
  final DateTime? checkedAt;
  final PlatformAdminActuatorExposure actuator;
  final PlatformAdminJvmSnapshot jvm;
  final PlatformAdminSystemSnapshot system;
  final Map<String, dynamic> info;

  factory PlatformAdminHealth.fromJson(Map<String, dynamic> json) {
    return PlatformAdminHealth(
      applicationStatus: json['applicationStatus'] as String? ?? '',
      checkedAt: _toDateTime(json['checkedAt']),
      actuator: PlatformAdminActuatorExposure.fromJson(
        json['actuator'] as Map<String, dynamic>? ?? const {},
      ),
      jvm: PlatformAdminJvmSnapshot.fromJson(
        json['jvm'] as Map<String, dynamic>? ?? const {},
      ),
      system: PlatformAdminSystemSnapshot.fromJson(
        json['system'] as Map<String, dynamic>? ?? const {},
      ),
      info: (json['info'] as Map<String, dynamic>?) ?? const {},
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
