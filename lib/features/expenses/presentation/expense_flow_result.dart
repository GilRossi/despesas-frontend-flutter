class ExpenseFlowResult {
  const ExpenseFlowResult({
    required this.shouldReload,
    this.message,
    this.expenseId,
  });

  const ExpenseFlowResult.reload({this.message, this.expenseId})
    : shouldReload = true;

  final bool shouldReload;
  final String? message;
  final int? expenseId;
}
