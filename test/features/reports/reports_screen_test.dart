import 'package:despesas_frontend/features/reports/presentation/reports_screen.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  SessionController buildSessionController() {
    return SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
  }

  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

  testWidgets('shows reports content when load succeeds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Leitura clara do mês financeiro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Distribuição por categoria'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Distribuição por categoria'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recomendações'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recomendações'), findsOneWidget);
  });

  testWidgets('shows empty message when selected month has no expenses', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(
            snapshot: fakeReportsSnapshot(
              summary: fakeReportSummary(
                totalExpenses: 0,
                totalAmount: 0,
                paidAmount: 0,
                remainingAmount: 0,
                categoryTotals: const [],
                topExpenses: const [],
              ),
              insights: fakeReportInsights(
                increaseAlerts: const [],
                recurringExpenses: const [],
              ),
              recommendations: const [],
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Período sem dados'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Período sem dados'), findsOneWidget);
  });

  testWidgets('shows pt-br month label with ç when needed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(
            snapshot: fakeReportsSnapshot(
              referenceMonth: DateTime(2026, 3, 1),
              insights: fakeReportInsights(recurringExpenses: const []),
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Março 2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nenhum padrão recorrente forte encontrado.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum padrão recorrente forte encontrado.'), findsOneWidget);
  });

  testWidgets('shows error state when reports request fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(
            error: fakeApiException(message: 'Falha simulada'),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os relatórios.'),
      findsOneWidget,
    );
    expect(find.text('Falha simulada'), findsOneWidget);
  });

  testWidgets('reloads reports when comparison filter changes', (tester) async {
    final repository = FakeReportsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: repository,
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(repository.loadCalls, 1);

    await tester.tap(find.text('Comparar com mês anterior'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(repository.lastComparePrevious, isFalse);
  });

  testWidgets('remains stable on reduced viewport', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Recomendações'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
