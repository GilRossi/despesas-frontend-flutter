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

  test(
    'submitQuestion exposes a generic error message when the API fails',
    () async {
      final viewModel = FinancialAssistantViewModel(
        financialAssistantRepository: FakeFinancialAssistantRepository(
          error: Exception('boom'),
        ),
        sessionController: buildSessionController(),
      );

      await viewModel.submitQuestion('Como posso economizar este mês?');

      expect(
        viewModel.errorMessage,
        'Não foi possível consultar o assistente.',
      );
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.entries, isEmpty);
    },
  );

  test(
    'selectStarterIntent exposes a generic error message when the API fails',
    () async {
      final viewModel = FinancialAssistantViewModel(
        financialAssistantRepository: FakeFinancialAssistantRepository(
          starterError: Exception('boom'),
        ),
        sessionController: buildSessionController(
          authRepository: FakeAuthRepository(
            loginResult: fakeSession(
              onboarding: const AuthOnboarding(completed: false),
            ),
          ),
        ),
      );

      await viewModel.selectStarterIntent(
        FinancialAssistantStarterIntent.fixedBills,
      );

      expect(
        viewModel.starterErrorMessage,
        'Não foi possível preparar essa próxima etapa.',
      );
      expect(viewModel.isStarterLoading, isFalse);
    },
  );

  test('retry methods do nothing when no previous attempt exists', () async {
    final viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: FakeFinancialAssistantRepository(),
      sessionController: buildSessionController(),
    );

    await viewModel.retryLastQuestion();
    await viewModel.retryStarterIntent();

    expect(viewModel.entries, isEmpty);
    expect(viewModel.starterReply, isNull);
  });

  test(
    'tour controls and month navigation keep internal state coherent',
    () async {
      final authRepository = FakeAuthRepository(
        loginResult: fakeSession(
          name: '',
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
        financialAssistantRepository: FakeFinancialAssistantRepository(),
        sessionController: sessionController,
        initialReferenceMonth: DateTime(2026, 3, 18),
      );

      expect(viewModel.firstName, 'voce');
      expect(viewModel.isTourVisible, isTrue);

      viewModel.dismissTour();
      expect(viewModel.isTourVisible, isFalse);

      viewModel.reopenTour();
      expect(viewModel.isTourVisible, isTrue);

      await viewModel.goToPreviousMonth();
      expect(viewModel.referenceMonth, DateTime(2026, 2));

      await viewModel.goToNextMonth();
      expect(viewModel.referenceMonth, DateTime(2026, 3));
    },
  );

  test(
    'completeOnboarding exposes API errors and no-op when onboarding is done',
    () async {
      final authRepository = FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        ),
        completeOnboardingError: const ApiException(
          statusCode: 422,
          message: 'Falha simulada',
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

      expect(viewModel.onboardingErrorMessage, 'Falha simulada');
      expect(viewModel.isCompletingOnboarding, isFalse);

      final completedAuthRepository = FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: true),
        ),
      );
      final completedController = buildSessionController(
        authRepository: completedAuthRepository,
      );
      await completedController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );
      final completedViewModel = FinancialAssistantViewModel(
        financialAssistantRepository: FakeFinancialAssistantRepository(),
        sessionController: completedController,
      );

      await completedViewModel.completeOnboarding();

      expect(completedAuthRepository.completeOnboardingCalls, 0);
      expect(completedViewModel.isTourVisible, isFalse);
    },
  );
}
