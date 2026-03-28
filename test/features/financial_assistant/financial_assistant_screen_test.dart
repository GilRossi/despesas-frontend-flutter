import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  SessionController buildSessionController({
    required AuthOnboarding onboarding,
    FakeAuthRepository? authRepository,
  }) {
    final repository =
        authRepository ??
        FakeAuthRepository(loginResult: fakeSession(onboarding: onboarding));
    final controller = SessionController(
      authRepository: repository,
      sessionStore: MemorySessionStore(),
    );
    return controller;
  }

  Future<SessionController> pumpAssistant(
    WidgetTester tester, {
    required AuthOnboarding onboarding,
    FakeAuthRepository? authRepository,
    FakeFinancialAssistantRepository? repository,
    ValueChanged<String>? onStarterPrimaryActionRequested,
  }) async {
    final controller = buildSessionController(
      onboarding: onboarding,
      authRepository: authRepository,
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository:
              repository ?? FakeFinancialAssistantRepository(),
          sessionController: controller,
          onStarterPrimaryActionRequested: onStarterPrimaryActionRequested,
        ),
      ),
    );

    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('first access shows welcome, tour and official starter options', (
    tester,
  ) async {
    await pumpAssistant(
      tester,
      onboarding: const AuthOnboarding(completed: false),
    );

    expect(find.text('Bem-vindo ao seu Espaco, Gil'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-tour-card')), findsOneWidget);
    expect(find.text('Cadastrar minhas contas fixas'), findsOneWidget);
    expect(find.text('Trazer meu historico'), findsOneWidget);
    expect(find.text('Cadastrar meus ganhos'), findsOneWidget);
    expect(find.text('Configurar meu Espaco'), findsOneWidget);
  });

  testWidgets('review tour button reopens the local tour', (tester) async {
    await pumpAssistant(
      tester,
      onboarding: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 12),
      ),
    );

    expect(find.byKey(const ValueKey('assistant-tour-card')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('assistant-reopen-tour-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('assistant-tour-card')), findsOneWidget);
  });

  testWidgets('starter intent response is rendered inside the assistant', (
    tester,
  ) async {
    final repository = FakeFinancialAssistantRepository(
      starterReply: fakeStarterReply(
        intent: FinancialAssistantStarterIntent.importHistory,
        title: 'Vamos organizar seu historico',
        message: 'Primeiro eu vou te orientar sobre o que trazer para ca.',
        primaryActionKey: 'OPEN_IMPORT_HISTORY',
      ),
    );

    await pumpAssistant(
      tester,
      onboarding: const AuthOnboarding(completed: false),
      repository: repository,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assistant-starter-import_history-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('assistant-starter-import_history-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.starterIntentCalls, 1);
    expect(
      repository.lastStarterIntent,
      FinancialAssistantStarterIntent.importHistory,
    );
    expect(
      find.byKey(const ValueKey('assistant-starter-response-card')),
      findsOneWidget,
    );
    expect(find.text('Vamos organizar seu historico'), findsOneWidget);
    expect(
      find.text('Primeiro eu vou te orientar sobre o que trazer para ca.'),
      findsOneWidget,
    );
  });

  testWidgets('starter primary action repassa OPEN_FIXED_BILLS para o shell', (
    tester,
  ) async {
    String? requestedAction;

    await pumpAssistant(
      tester,
      onboarding: const AuthOnboarding(completed: false),
      repository: FakeFinancialAssistantRepository(
        starterReply: fakeStarterReply(
          intent: FinancialAssistantStarterIntent.fixedBills,
          title: 'Vamos registrar sua conta fixa',
          message: 'Revise a base antes de confirmar.',
          primaryActionKey: 'OPEN_FIXED_BILLS',
        ),
      ),
      onStarterPrimaryActionRequested: (actionKey) {
        requestedAction = actionKey;
      },
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assistant-starter-fixed_bills-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('assistant-starter-fixed_bills-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assistant-starter-primary-action')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('assistant-starter-primary-action')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(requestedAction, 'OPEN_FIXED_BILLS');
  });

  testWidgets('completing onboarding updates session and closes the tour', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(
        onboarding: const AuthOnboarding(completed: false),
      ),
      completeOnboardingResult: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 19),
      ),
    );

    final controller = await pumpAssistant(
      tester,
      onboarding: const AuthOnboarding(completed: false),
      authRepository: authRepository,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assistant-complete-onboarding-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('assistant-complete-onboarding-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(authRepository.completeOnboardingCalls, 1);
    expect(controller.currentUser?.onboarding.completed, isTrue);
    expect(find.byKey(const ValueKey('assistant-tour-card')), findsNothing);
  });

  testWidgets('submits a financial question and renders assistant answer', (
    tester,
  ) async {
    await pumpAssistant(
      tester,
      onboarding: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 12),
      ),
      repository: FakeFinancialAssistantRepository(
        reply: fakeFinancialAssistantReply(
          question: 'Como posso economizar este mes?',
          answer: 'Revise moradia e despesas recorrentes.',
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField),
      'Como posso economizar este mes?',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assistant-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('assistant-submit-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resposta do assistente'), findsOneWidget);
    expect(find.text('Revise moradia e despesas recorrentes.'), findsOneWidget);
    expect(find.text('Sinais de apoio'), findsOneWidget);
  });
}
