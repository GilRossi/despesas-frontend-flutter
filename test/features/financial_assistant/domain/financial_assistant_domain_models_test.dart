import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financial assistant reply decodes all supporting data blocks', () {
    final reply = FinancialAssistantReply.fromJson({
      'question': 'Onde gastei mais?',
      'mode': 'AI',
      'intent': 'HIGHEST_SPENDING_CATEGORY',
      'answer': 'Voce gastou mais com moradia.',
      'summary': {
        'from': '2026-03-01',
        'to': '2026-03-31',
        'totalExpenses': '3',
        'totalAmount': '450.00',
        'paidAmount': 120,
        'remainingAmount': 330.0,
        'highestSpendingCategory': 'Moradia',
        'categoryTotals': [
          {
            'categoryId': '1',
            'categoryName': 'Moradia',
            'totalAmount': '300.00',
            'expensesCount': 2.0,
            'sharePercentage': 66.67,
          },
        ],
        'topExpenses': [
          {
            'expenseId': '10',
            'description': 'Aluguel',
            'amount': '250.00',
            'dueDate': '2026-03-10',
            'categoryName': 'Moradia',
            'subcategoryName': 'Aluguel',
            'context': 'CASA',
          },
        ],
      },
      'monthComparison': {
        'currentMonth': '2026-03',
        'currentTotal': '450.00',
        'previousMonth': '2026-02',
        'previousTotal': 400,
        'deltaAmount': 50.0,
        'deltaPercentage': '12.50',
      },
      'highestSpendingCategory': {
        'categoryId': 1,
        'categoryName': 'Moradia',
        'totalAmount': '300.00',
        'expensesCount': '2',
        'sharePercentage': 66.67,
      },
      'topExpenses': [
        {
          'expenseId': 10,
          'description': 'Aluguel',
          'amount': 250.0,
          'dueDate': '2026-03-10',
          'categoryName': 'Moradia',
          'subcategoryName': 'Aluguel',
          'context': 'CASA',
        },
      ],
      'increaseAlerts': [
        {
          'categoryName': 'Moradia',
          'currentAmount': '300.00',
          'previousAmount': 200,
          'deltaAmount': 100.0,
          'deltaPercentage': '50.00',
        },
      ],
      'recurringExpenses': [
        {
          'description': 'Internet',
          'categoryName': 'Moradia',
          'subcategoryName': 'Internet',
          'averageAmount': '99.90',
          'occurrences': '3',
          'likelyFixedAmount': true,
          'lastOccurrence': '2026-03-20',
        },
      ],
      'recommendations': [
        {
          'title': 'Renegociar internet',
          'rationale': 'Valor subiu',
          'action': 'Pedir desconto',
        },
      ],
      'aiUsage': {
        'model': 'deepseek-chat',
        'inputTokens': '100',
        'outputTokens': 30,
        'totalTokens': 130.0,
        'cachedInputTokens': '10',
        'reasoningTokens': 5,
        'toolExecutionCount': '2',
        'finishReason': 'stop',
      },
    });

    expect(reply.question, 'Onde gastei mais?');
    expect(reply.usesAi, isTrue);
    expect(reply.hasSupportingData, isTrue);
    expect(reply.summary?.hasData, isTrue);
    expect(reply.summary?.categoryTotals.single.categoryId, 1);
    expect(reply.summary?.topExpenses.single.expenseId, 10);
    expect(reply.monthComparison?.deltaPercentage, 12.5);
    expect(reply.highestSpendingCategory?.expensesCount, 2);
    expect(reply.topExpenses.single.description, 'Aluguel');
    expect(reply.increaseAlerts.single.deltaAmount, 100);
    expect(reply.recurringExpenses.single.occurrences, 3);
    expect(reply.recommendations.single.title, 'Renegociar internet');
    expect(reply.aiUsage?.totalTokens, 130);
    expect(reply.aiUsage?.toolExecutionCount, 2);
  });

  test('financial assistant reply stays minimal when payload has no data', () {
    final reply = FinancialAssistantReply.fromJson({
      'question': null,
      'mode': 'FALLBACK',
      'intent': null,
      'answer': null,
      'summary': null,
      'monthComparison': null,
      'highestSpendingCategory': null,
      'topExpenses': [],
      'increaseAlerts': [],
      'recurringExpenses': [],
      'recommendations': [],
      'aiUsage': null,
    });

    expect(reply.question, '');
    expect(reply.answer, '');
    expect(reply.usesAi, isFalse);
    expect(reply.hasSupportingData, isFalse);
    expect(reply.summary, isNull);
    expect(reply.aiUsage, isNull);
  });

  test('starter intent resolves valid api values and rejects unknown ones', () {
    expect(
      FinancialAssistantStarterIntent.fromApiValue('FIXED_BILLS'),
      FinancialAssistantStarterIntent.fixedBills,
    );
    expect(
      FinancialAssistantStarterIntent.registerIncome.apiValue,
      'REGISTER_INCOME',
    );
    expect(
      () => FinancialAssistantStarterIntent.fromApiValue('UNKNOWN'),
      throwsArgumentError,
    );
  });
}
