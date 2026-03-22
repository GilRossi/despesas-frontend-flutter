class CreateHouseholdOwnerInput {
  const CreateHouseholdOwnerInput({
    required this.householdName,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPassword,
  });

  final String householdName;
  final String ownerName;
  final String ownerEmail;
  final String ownerPassword;
}
