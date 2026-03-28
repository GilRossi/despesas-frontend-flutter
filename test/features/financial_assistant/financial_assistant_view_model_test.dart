import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  SessionController buildSessionController({
    FakeAuthRepository? authRepository,
  }) {
    return SessionController(
      authRepository: authRepository ?? FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
  }

  test('submitQuestion appends reply to local conversation', () async {
    final repository = FakeFinancialAssistantRepository(
      reply: fakeFinancialAssistantReply(question: 'Onde estou gastando mais?'),
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: repository,
      sessionController: buildSessionController(),
    );

    await viewModel.submitQuestion('Onde estou gastando mais?');

    expect(repository.askCalls, 1);
    expect(viewModel.entries, hasLength(1));
    expect(
      viewModel.entries.single.reply.question,
      'Onde estou gastando mais?',
    );
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
      sessionController: buildSessionController(),
    );

    await viewModel.submitQuestion('Como posso economizar este mes?');

    expect(viewModel.isUnauthorized, isTrue);
    expect(viewModel.errorMessage, 'Sua sessao expirou. Faca login novamente.');
    expect(viewModel.entries, isEmpty);
  });

  test('retryLastQuestion resubmits the previous question', () async {
    final repository = FakeFinancialAssistantRepository(
      error: const ApiException(statusCode: 422, message: 'Falha temporaria'),
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: repository,
      sessionController: buildSessionController(),
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

  test('starter intent returns structured response from backend', () async {
    final repository = FakeFinancialAssistantRepository(
      starterReply: fakeStarterReply(
        title: 'Vamos comecar pelos ganhos',
        message: 'Primeiro eu te ajudo a registrar as entradas do mes.',
        primaryActionKey: 'OPEN_REGISTER_INCOME',
      ),
    );
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(
        onboarding: const AuthOnboarding(completed: false),
      ),
    );
    final sessionController = buildSessionController(
      authRepository: authRepository,
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: repository,
      sessionController: sessionController,
    );

    await viewModel.selectStarterIntent(
      FinancialAssistantStarterIntent.registerIncome,
    );

    expect(repository.starterIntentCalls, 1);
    expect(viewModel.starterReply?.primaryActionKey, 'OPEN_REGISTER_INCOME');
  });

  test('completeOnboarding updates the session and closes the tour', () async {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(
        onboarding: const AuthOnboarding(completed: false),
      ),
      completeOnboardingResult: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 18),
      ),
    );
    final sessionController = buildSessionController(
      authRepository: authRepository,
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: FakeFinancialAssistantRepository(),
      sessionController: sessionController,
    );

    await viewModel.completeOnboarding();

    expect(viewModel.showWelcome, isFalse);
    expect(viewModel.isTourVisible, isFalse);
    expect(sessionController.currentUser?.onboarding.completed, isTrue);
  });
}
