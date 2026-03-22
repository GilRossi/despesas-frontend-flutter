import 'dart:async';

import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

  testWidgets('shows useful initial state before first question', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: FakeFinancialAssistantRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Assistente financeiro oficial do household'), findsOneWidget);
    expect(find.text('Estado inicial util'), findsOneWidget);
    expect(find.text('Perguntar'), findsOneWidget);
  });

  testWidgets('submits a financial question and renders assistant answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: FakeFinancialAssistantRepository(
            reply: fakeFinancialAssistantReply(
              question: 'Como posso economizar este mes?',
              answer: 'Revise moradia e despesas recorrentes.',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Como posso economizar este mes?',
    );
    await tester.scrollUntilVisible(
      find.text('Perguntar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perguntar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Resposta do assistente'), findsOneWidget);
    expect(find.text('Revise moradia e despesas recorrentes.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sinais de apoio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sinais de apoio'), findsOneWidget);
  });

  testWidgets('submits a starter suggestion directly', (tester) async {
    final repository = FakeFinancialAssistantRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Onde estou gastando mais?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onde estou gastando mais?'));
    await tester.pumpAndSettle();

    expect(repository.askCalls, 1);
    expect(repository.lastQuestion, 'Onde estou gastando mais?');
  });

  testWidgets('shows loading feedback while assistant response is pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = FakeFinancialAssistantRepository(
      onAsk: (question, referenceMonth) async {
        await completer.future;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Como vai o meu mes?');
    await tester.scrollUntilVisible(
      find.text('Perguntar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perguntar'), warnIfMissed: false);
    await tester.pump();

    expect(
      find.textContaining('Consultando o backend do assistente financeiro'),
      findsOneWidget,
    );

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows error feedback when assistant request fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: FakeFinancialAssistantRepository(
            error: fakeApiException(message: 'Falha simulada'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Como vai o meu mes?');
    await tester.scrollUntilVisible(
      find.text('Perguntar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perguntar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('Nao foi possivel consultar o assistente.'),
      findsOneWidget,
    );
    expect(find.text('Falha simulada'), findsOneWidget);
  });

  testWidgets('remains stable on reduced viewport', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: FakeFinancialAssistantRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Perguntar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-scrolls to the latest assistant answer on small screens', (
    tester,
  ) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FinancialAssistantScreen(
          financialAssistantRepository: FakeFinancialAssistantRepository(
            reply: fakeFinancialAssistantReply(
              question: 'Como posso economizar este mes?',
              answer: 'Resposta visivel sem exigir scroll manual.',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Como posso economizar este mes?',
    );
    await tester.scrollUntilVisible(
      find.text('Perguntar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perguntar'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final viewportHeight = tester.view.physicalSize.height;
    final answerPosition = tester.getTopLeft(find.text('Resposta do assistente'));

    expect(answerPosition.dy, lessThan(viewportHeight));
  });
}
