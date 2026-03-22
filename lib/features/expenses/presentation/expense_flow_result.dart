class ExpenseFlowResult {
  const ExpenseFlowResult({required this.shouldReload, this.message});

  const ExpenseFlowResult.reload({this.message}) : shouldReload = true;

  final bool shouldReload;
  final String? message;
}
