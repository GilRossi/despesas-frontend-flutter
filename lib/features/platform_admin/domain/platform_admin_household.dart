class PlatformAdminHousehold {
  const PlatformAdminHousehold({
    required this.householdId,
    required this.householdName,
    required this.ownerUserId,
    required this.ownerEmail,
    required this.ownerRole,
  });

  final int householdId;
  final String householdName;
  final int ownerUserId;
  final String ownerEmail;
  final String ownerRole;

  factory PlatformAdminHousehold.fromJson(Map<String, dynamic> json) {
    return PlatformAdminHousehold(
      householdId: json['householdId'] as int,
      householdName: json['householdName'] as String,
      ownerUserId: json['ownerUserId'] as int,
      ownerEmail: json['ownerEmail'] as String,
      ownerRole: json['ownerRole'] as String,
    );
  }
}
