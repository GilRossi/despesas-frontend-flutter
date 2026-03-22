import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';

class FinancialAssistantConversationEntry {
  const FinancialAssistantConversationEntry({
    required this.referenceMonth,
    required this.reply,
  });

  final DateTime referenceMonth;
  final FinancialAssistantReply reply;
}
