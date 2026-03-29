import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/dashboard/data/http_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'fetchDashboard consome o contrato unico do dashboard role-aware',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'role': 'OWNER',
              'summaryMain': {
                'referenceMonth': '2026-03',
                'totalOpenAmount': 320.0,
                'totalOverdueAmount': 120.0,
                'paidThisMonthAmount': 540.0,
                'openCount': 2,
                'overdueCount': 1,
              },
              'actionNeeded': {
                'overdueCount': 1,
                'overdueAmount': 120.0,
                'openCount': 2,
                'openAmount': 320.0,
                'items': [
                  {
                    'expenseId': 10,
                    'description': 'Internet',
                    'dueDate': '2026-03-10',
                    'status': 'VENCIDA',
                    'amount': 120.0,
                    'route': '/expenses/10/pay',
                  },
                ],
              },
              'recentActivity': {
                'items': [
                  {
                    'type': 'PAYMENT_RECORDED',
                    'title': 'Pagamento registrado',
                    'subtitle': 'Aluguel',
                    'amount': 500.0,
                    'occurredAt': '2026-03-29T12:00:00Z',
                    'route': '/expenses',
                  },
                ],
              },
              'assistantCard': {
                'title': 'Assistente financeiro',
                'message': 'Revise a categoria que mais pesa.',
                'primaryActionKey': 'OPEN_ASSISTANT',
                'route': '/assistant',
              },
              'monthOverview': {
                'referenceMonth': '2026-03',
                'totalAmount': 860.0,
                'paidAmount': 540.0,
                'remainingAmount': 320.0,
                'monthComparison': {
                  'currentMonth': '2026-03',
                  'currentTotal': 860.0,
                  'previousMonth': '2026-02',
                  'previousTotal': 700.0,
                  'deltaAmount': 160.0,
                  'deltaPercentage': 22.86,
                },
                'highestSpendingCategory': {
                  'categoryId': 1,
                  'categoryName': 'Moradia',
                  'totalAmount': 540.0,
                  'sharePercentage': 62.79,
                },
              },
              'categorySpending': {
                'items': [
                  {
                    'categoryId': 1,
                    'categoryName': 'Moradia',
                    'totalAmount': 540.0,
                    'expensesCount': 2,
                    'sharePercentage': 62.79,
                  },
                ],
              },
              'householdSummary': {
                'membersCount': 3,
                'ownersCount': 1,
                'membersOnlyCount': 2,
                'spaceReferencesCount': 4,
                'referencesByGroup': [
                  {'group': 'RESIDENCIAL', 'count': 2},
                ],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sessionController = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: true),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );
      await sessionController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );

      final repository = HttpDashboardRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final result = await repository.fetchDashboard();

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/dashboard',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(result.isOwner, isTrue);
      expect(result.summaryMain.referenceMonth, '2026-03');
      expect(result.actionNeeded.items.first.status, 'VENCIDA');
      expect(result.actionNeeded.items.first.route, '/expenses/10/pay');
      expect(result.assistantCard.route, '/assistant');
      expect(
        result.monthOverview?.highestSpendingCategory?.categoryName,
        'Moradia',
      );
      expect(result.categorySpending?.items.first.categoryName, 'Moradia');
      expect(
        result.householdSummary?.referencesByGroup.first.group.apiValue,
        'RESIDENCIAL',
      );
      expect(result.quickActions, isNull);
    },
  );

  test('fetchDashboard propaga erro quando o contrato vem invalido', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: true),
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );

    final repository = HttpDashboardRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );

    expect(
      repository.fetchDashboard(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });
}
