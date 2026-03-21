import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('submitQuestion appends reply to local conversation', () async {
    final repository = FakeFinancialAssistantRepository(
      reply: fakeFinancialAssistantReply(question: 'Onde estou gastando mais?'),
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: repository,
    );

    await viewModel.submitQuestion('Onde estou gastando mais?');

    expect(repository.askCalls, 1);
    expect(viewModel.entries, hasLength(1));
    expect(viewModel.entries.single.reply.question, 'Onde estou gastando mais?');
    expect(viewModel.errorMessage, isNull);
  });

  test('submitQuestion exposes unauthorized state from API', () async {
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: FakeFinancialAssistantRepository(
        error: const ApiException(
          statusCode: 401,
          message: 'Sua sessao expirou. Faca login novamente.',
        ),
      ),
    );

    await viewModel.submitQuestion('Como posso economizar este mes?');

    expect(viewModel.isUnauthorized, isTrue);
    expect(
      viewModel.errorMessage,
      'Sua sessao expirou. Faca login novamente.',
    );
    expect(viewModel.entries, isEmpty);
  });

  test('retryLastQuestion resubmits the previous question', () async {
    final repository = FakeFinancialAssistantRepository(
      error: const ApiException(statusCode: 422, message: 'Falha temporaria'),
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: repository,
    );

    await viewModel.submitQuestion('Como este mes se compara ao anterior?');
    repository
      ..error = null
      ..reply = fakeFinancialAssistantReply(
        question: 'Como este mes se compara ao anterior?',
      );

    await viewModel.retryLastQuestion();

    expect(repository.askCalls, 2);
    expect(viewModel.entries, hasLength(1));
    expect(
      viewModel.entries.single.reply.question,
      'Como este mes se compara ao anterior?',
    );
  });
}
