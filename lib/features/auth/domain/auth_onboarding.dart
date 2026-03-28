class AuthOnboarding {
  const AuthOnboarding({required this.completed, this.completedAt});

  final bool completed;
  final DateTime? completedAt;

  factory AuthOnboarding.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'] as String?;
    return AuthOnboarding(
      completed: json['completed'] as bool? ?? false,
      completedAt: completedAt == null || completedAt.isEmpty
          ? null
          : DateTime.parse(completedAt),
    );
  }

  AuthOnboarding copyWith({bool? completed, DateTime? completedAt}) {
    return AuthOnboarding(
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
