import 'package:despesas_frontend/features/reports/presentation/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

  testWidgets('shows reports content when load succeeds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(reportsRepository: FakeReportsRepository()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Leitura clara do mes financeiro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Breakdown por categoria'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Breakdown por categoria'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recomendacoes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recomendacoes'), findsOneWidget);
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
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Periodo sem dados'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Periodo sem dados'), findsOneWidget);
  });

  testWidgets('shows error state when reports request fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          reportsRepository: FakeReportsRepository(
            error: fakeApiException(message: 'Falha simulada'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Nao foi possivel carregar os relatorios.'),
      findsOneWidget,
    );
    expect(find.text('Falha simulada'), findsOneWidget);
  });

  testWidgets('reloads reports when comparison filter changes', (tester) async {
    final repository = FakeReportsRepository();

    await tester.pumpWidget(
      MaterialApp(home: ReportsScreen(reportsRepository: repository)),
    );

    await tester.pumpAndSettle();
    expect(repository.loadCalls, 1);

    await tester.tap(find.text('Comparar com mes anterior'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(repository.lastComparePrevious, isFalse);
  });

  testWidgets('remains stable on reduced viewport', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(reportsRepository: FakeReportsRepository()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Recomendacoes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
