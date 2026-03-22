class CreateExpensePaymentInput {
  const CreateExpensePaymentInput({
    required this.expenseId,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.notes,
  });

  final int expenseId;
  final double amount;
  final DateTime paidAt;
  final String method;
  final String notes;
}
