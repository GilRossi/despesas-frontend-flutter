class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final int userId;
  final int householdId;
  final String name;
  final String email;
  final String role;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'] as int,
      userId: json['userId'] as int,
      householdId: json['householdId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
