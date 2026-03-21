import 'package:despesas_frontend/app/despesas_app.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:despesas_frontend/features/auth/data/secure_session_store.dart';
import 'package:despesas_frontend/features/expenses/data/http_expenses_repository.dart';
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
  final authRepository = HttpAuthRepository(apiClient);
  final sessionController = SessionController(
    authRepository: authRepository,
    sessionStore: sessionStore,
  );
  final authorizedRequestExecutor = AuthorizedRequestExecutor(
    apiClient: apiClient,
    sessionManager: sessionController,
  );
  final expensesRepository = HttpExpensesRepository(authorizedRequestExecutor);

  runApp(
    DespesasApp(
      environment: environment,
      sessionController: sessionController,
      expensesRepository: expensesRepository,
    ),
  );
}
