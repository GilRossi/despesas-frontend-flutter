import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';

class FinancialAssistantStarterReply {
  const FinancialAssistantStarterReply({
    required this.intent,
    required this.kind,
    required this.title,
    required this.message,
    required this.primaryActionKey,
  });

  final FinancialAssistantStarterIntent intent;
  final String kind;
  final String title;
  final String message;
  final String primaryActionKey;

  factory FinancialAssistantStarterReply.fromJson(Map<String, dynamic> json) {
    return FinancialAssistantStarterReply(
      intent: FinancialAssistantStarterIntent.fromApiValue(
        json['intent'] as String? ?? '',
      ),
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      primaryActionKey: json['primaryActionKey'] as String? ?? '',
    );
  }
}
