class AuthUser {
  const AuthUser({
    required this.userId,
    required this.householdId,
    required this.email,
    required this.name,
    required this.role,
  });

  final int userId;
  final int householdId;
  final String email;
  final String name;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int,
      householdId: json['householdId'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}
