import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.householdId,
    required this.email,
    required this.name,
    required this.role,
    this.onboarding = const AuthOnboarding(completed: false),
  });

  final int userId;
  final int? householdId;
  final String email;
  final String name;
  final String role;
  final AuthOnboarding onboarding;

  bool get needsOnboarding => !onboarding.completed;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final onboarding = json['onboarding'];
    return AuthUser(
      userId: json['userId'] as int,
      householdId: json['householdId'] as int?,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      onboarding: onboarding is Map<String, dynamic>
          ? AuthOnboarding.fromJson(onboarding)
          : const AuthOnboarding(completed: false),
    );
  }

  AuthUser copyWith({
    int? userId,
    int? householdId,
    String? email,
    String? name,
    String? role,
    AuthOnboarding? onboarding,
  }) {
    return AuthUser(
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      onboarding: onboarding ?? this.onboarding,
    );
  }
}
