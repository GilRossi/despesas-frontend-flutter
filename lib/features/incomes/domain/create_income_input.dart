class CreateIncomeInput {
  const CreateIncomeInput({
    required this.description,
    required this.amount,
    required this.receivedOn,
    this.spaceReferenceId,
  });

  final String description;
  final double amount;
  final DateTime receivedOn;
  final int? spaceReferenceId;

  Map<String, Object?> toJson() {
    final month = receivedOn.month.toString().padLeft(2, '0');
    final day = receivedOn.day.toString().padLeft(2, '0');

    return {
      'description': description.trim(),
      'amount': amount,
      'receivedOn': '${receivedOn.year}-$month-$day',
      'spaceReferenceId': spaceReferenceId,
    };
  }
}
