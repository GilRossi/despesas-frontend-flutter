class FinancialAssistantAiUsage {
  const FinancialAssistantAiUsage({
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.cachedInputTokens,
    required this.reasoningTokens,
    required this.toolExecutionCount,
    required this.finishReason,
  });

  final String model;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final int cachedInputTokens;
  final int reasoningTokens;
  final int toolExecutionCount;
  final String finishReason;

  factory FinancialAssistantAiUsage.fromJson(Map<String, dynamic> json) {
    return FinancialAssistantAiUsage(
      model: json['model'] as String? ?? '',
      inputTokens: _toInt(json['inputTokens']),
      outputTokens: _toInt(json['outputTokens']),
      totalTokens: _toInt(json['totalTokens']),
      cachedInputTokens: _toInt(json['cachedInputTokens']),
      reasoningTokens: _toInt(json['reasoningTokens']),
      toolExecutionCount: _toInt(json['toolExecutionCount']),
      finishReason: json['finishReason'] as String? ?? '',
    );
  }

  static int _toInt(Object? value) {
    return switch (value) {
      int number => number,
      double number => number.toInt(),
      String number => int.parse(number),
      _ => 0,
    };
  }
}
