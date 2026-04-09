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

    expect(find.text('Assistente financeiro do seu espaço'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-tour-card')), findsOneWidget);
    expect(find.text('Seja bem-vindo(a) ao seu espaço'), findsOneWidget);
    expect(
      find.text(
        'Use quando quiser tirar uma dúvida ou escolher o próximo passo. O sistema continua funcionando mesmo sem o assistente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Escolha por onde quer começar'), findsOneWidget);
    expect(find.text('Cadastrar minhas contas fixas'), findsOneWidget);
    expect(find.text('Trazer meu histórico'), findsOneWidget);
    expect(find.text('Cadastrar meus ganhos'), findsOneWidget);
    expect(find.text('Configurar meu espaço'), findsOneWidget);
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
    expect(find.text('Vamos trazer seu histórico'), findsOneWidget);
    expect(
      find.text(
        'Se você já organiza sua vida financeira em outro lugar, comece trazendo esse histórico.',
      ),
      findsOneWidget,
    );
    expect(find.text('STARTER'), findsNothing);
    expect(find.text('Import History'), findsNothing);
    expect(find.text('Open Import History'), findsNothing);
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
    expect(find.text('Abrir cadastro de contas fixas'), findsOneWidget);
  });

  testWidgets(
    'starter primary action repassa OPEN_IMPORT_HISTORY para o shell',
    (tester) async {
      String? requestedAction;

      await pumpAssistant(
        tester,
        onboarding: const AuthOnboarding(completed: false),
        repository: FakeFinancialAssistantRepository(
          starterReply: fakeStarterReply(
            intent: FinancialAssistantStarterIntent.importHistory,
            title: 'Vamos trazer seu historico',
            message: 'Monte o lote antes de confirmar.',
            primaryActionKey: 'OPEN_IMPORT_HISTORY',
          ),
        ),
        onStarterPrimaryActionRequested: (actionKey) {
          requestedAction = actionKey;
        },
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

      expect(requestedAction, 'OPEN_IMPORT_HISTORY');
      expect(find.text('Abrir importação de histórico'), findsOneWidget);
    },
  );

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
          question: 'Como posso economizar este mês?',
          mode: 'FALLBACK',
          intent: 'PERIOD_SUMMARY',
          answer: 'Nao ha despesas registradas em 2026-03.',
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField),
      'Como posso economizar este mês?',
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
    expect(
      find.text('Não há despesas registradas em março/2026.'),
      findsOneWidget,
    );
    expect(find.text('Dados usados na resposta'), findsOneWidget);
    expect(find.text('Modo FALLBACK'), findsNothing);
    expect(find.text('Period Summary'), findsNothing);
    expect(find.text('deepseek-chat · 120 tokens'), findsNothing);
  });

  testWidgets('shows approved loading and validation copy', (tester) async {
    await pumpAssistant(
      tester,
      onboarding: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 12),
      ),
      repository: FakeFinancialAssistantRepository(
        onAsk: (question, referenceMonth) =>
            Future<void>.delayed(const Duration(milliseconds: 300)),
      ),
    );

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    await tester.pump();

    expect(find.text('Informe uma pergunta financeira.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'Quero revisar meus gastos deste mês.',
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
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tentando buscar sua resposta...'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  });
}
