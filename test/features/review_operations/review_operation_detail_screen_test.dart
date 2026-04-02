import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_screen.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_flow_result.dart';
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

  testWidgets('shows review detail content when load succeeds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationDetailScreen(
          ingestionId: 51,
          reviewOperationsRepository: FakeReviewOperationsRepository(
            detailResult: fakeReviewDetail(),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Compra Cobasi'), findsOneWidget);
    expect(find.text('Dados da importação'), findsOneWidget);
    expect(find.text('Itens extraídos'), findsOneWidget);
  });

  testWidgets('approves review and returns reload result to parent', (
    tester,
  ) async {
    final repository = FakeReviewOperationsRepository(
      detailResult: fakeReviewDetail(),
    );
    Future<ReviewOperationsFlowResult?>? resultFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    resultFuture = Navigator.of(context)
                        .push<ReviewOperationsFlowResult>(
                          MaterialPageRoute(
                            builder: (_) => ReviewOperationDetailScreen(
                              ingestionId: 51,
                              reviewOperationsRepository: repository,
                              sessionController: buildSessionController(),
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir review'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir review'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Aprovar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.approveCalls, 1);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Revisão aprovada com sucesso.');
  });

  testWidgets('rejects review and returns reload result to parent', (
    tester,
  ) async {
    final repository = FakeReviewOperationsRepository(
      detailResult: fakeReviewDetail(),
    );
    Future<ReviewOperationsFlowResult?>? resultFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    resultFuture = Navigator.of(context)
                        .push<ReviewOperationsFlowResult>(
                          MaterialPageRoute(
                            builder: (_) => ReviewOperationDetailScreen(
                              ingestionId: 51,
                              reviewOperationsRepository: repository,
                              sessionController: buildSessionController(),
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir review'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir review'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rejeitar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejeitar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.rejectCalls, 1);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Revisão rejeitada com sucesso.');
  });

  testWidgets('shows action error feedback when approve fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationDetailScreen(
          ingestionId: 51,
          reviewOperationsRepository: FakeReviewOperationsRepository(
            detailResult: fakeReviewDetail(),
            approveError: fakeApiException(
              statusCode: 422,
              message:
                  'A ingestao selecionada nao esta mais pendente de revisao.',
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Aprovar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('A ingestao selecionada nao esta mais pendente de revisao.'),
      findsOneWidget,
    );
  });

  testWidgets('reflects access denied from api on detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationDetailScreen(
          ingestionId: 51,
          reviewOperationsRepository: FakeReviewOperationsRepository(
            detailError: fakeApiException(
              statusCode: 403,
              message: 'Access denied',
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Acesso negado'), findsOneWidget);
    expect(find.text('Access denied'), findsOneWidget);
  });

  testWidgets('remains stable on small heights', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewOperationDetailScreen(
          ingestionId: 51,
          reviewOperationsRepository: FakeReviewOperationsRepository(
            detailResult: fakeReviewDetail(),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Itens extraídos'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
