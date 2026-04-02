import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_screen.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_screen.dart';
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

  testWidgets('shows empty state when there are no pending reviews', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationsListScreen(
          reviewOperationsRepository: FakeReviewOperationsRepository(
            listResult: emptyReviewPage(),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Nenhuma revisão pendente'), findsOneWidget);
  });

  testWidgets('shows error state when review list fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationsListScreen(
          reviewOperationsRepository: FakeReviewOperationsRepository(
            listError: fakeApiException(message: 'Falha simulada'),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Não foi possível carregar as revisões.'), findsOneWidget);
    expect(find.text('Falha simulada'), findsOneWidget);
  });

  testWidgets('reflects access denied from api on list screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationsListScreen(
          reviewOperationsRepository: FakeReviewOperationsRepository(
            listError: fakeApiException(
              statusCode: 403,
              message: 'Access denied',
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Acesso negado'), findsOneWidget);
    expect(find.text('Access denied'), findsOneWidget);
  });

  testWidgets('opens review detail when tapping a pending review', (
    tester,
  ) async {
    final repository = FakeReviewOperationsRepository(
      listResult: PagedResult(
        items: [fakeReviewSummary()],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      ),
      detailResult: fakeReviewDetail(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationsListScreen(
          reviewOperationsRepository: repository,
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Compra Cobasi'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewOperationDetailScreen), findsOneWidget);
    expect(repository.detailCalls, 1);
  });
}
