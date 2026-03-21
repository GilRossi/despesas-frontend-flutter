class ReviewOperationsFlowResult {
  const ReviewOperationsFlowResult({required this.shouldReload, this.message});

  const ReviewOperationsFlowResult.reload({this.message}) : shouldReload = true;

  final bool shouldReload;
  final String? message;
}
