import 'package:despesas_frontend/app/despesas_app.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:despesas_frontend/features/auth/data/secure_session_store.dart';
import 'package:despesas_frontend/features/expenses/data/http_expenses_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/data/http_financial_assistant_repository.dart';
import 'package:despesas_frontend/features/dashboard/data/http_dashboard_repository.dart';
import 'package:despesas_frontend/features/household_members/data/http_household_members_repository.dart';
import 'package:despesas_frontend/features/platform_admin/data/http_platform_admin_repository.dart';
import 'package:despesas_frontend/features/reports/data/http_reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/data/http_review_operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.fromEnvironment();
  final httpClient = http.Client();
  final apiClient = DespesasApiClient(
    baseUrl: environment.apiBaseUrl,
    httpClient: httpClient,
  );
  final sessionStore = SecureSessionStore(const FlutterSecureStorage());
  late final SessionController sessionController;
  final authRepository = HttpAuthRepository(
    apiClient,
    accessTokenProvider: () => sessionController.accessToken,
  );
  sessionController = SessionController(
    authRepository: authRepository,
    sessionStore: sessionStore,
  );
  final authorizedRequestExecutor = AuthorizedRequestExecutor(
    apiClient: apiClient,
    sessionManager: sessionController,
  );
  final dashboardRepository = HttpDashboardRepository(authorizedRequestExecutor);
  final expensesRepository = HttpExpensesRepository(authorizedRequestExecutor);
  final financialAssistantRepository = HttpFinancialAssistantRepository(
    authorizedRequestExecutor,
  );
  final householdMembersRepository = HttpHouseholdMembersRepository(
    authorizedRequestExecutor,
  );
  final platformAdminRepository = HttpPlatformAdminRepository(
    authorizedRequestExecutor,
  );
  final reportsRepository = HttpReportsRepository(authorizedRequestExecutor);
  final reviewOperationsRepository = HttpReviewOperationsRepository(
    authorizedRequestExecutor,
  );

  runApp(
    DespesasApp(
      environment: environment,
      sessionController: sessionController,
      expensesRepository: expensesRepository,
      financialAssistantRepository: financialAssistantRepository,
      householdMembersRepository: householdMembersRepository,
      platformAdminRepository: platformAdminRepository,
      reportsRepository: reportsRepository,
      reviewOperationsRepository: reviewOperationsRepository,
      dashboardRepository: dashboardRepository,
    ),
  );
}
