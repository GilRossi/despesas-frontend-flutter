import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_reply.dart';

abstract interface class FinancialAssistantRepository {
  Future<FinancialAssistantReply> askQuestion({
    required String question,
    required DateTime referenceMonth,
  });

  Future<FinancialAssistantStarterReply> fetchStarterIntent({
    required FinancialAssistantStarterIntent intent,
  });
}
