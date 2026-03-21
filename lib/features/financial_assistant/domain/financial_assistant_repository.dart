import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';

abstract interface class FinancialAssistantRepository {
  Future<FinancialAssistantReply> askQuestion({
    required String question,
    required DateTime referenceMonth,
  });
}
