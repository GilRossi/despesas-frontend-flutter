import 'dart:io';

import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/expenses/data/http_expenses_repository.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final baseUrl = _requiredEnv('API_BASE_URL');
  final email = _requiredEnv('SMOKE_EMAIL');
  final password = _requiredEnv('SMOKE_PASSWORD');

  final httpClient = http.Client();
  final apiClient = DespesasApiClient(
    baseUrl: Uri.parse(baseUrl),
    httpClient: httpClient,
  );
  final authRepository = HttpAuthRepository(apiClient);
  final sessionManager = _SmokeSessionManager(authRepository: authRepository);
  final expensesRepository = HttpExpensesRepository(
    AuthorizedRequestExecutor(
      apiClient: apiClient,
      sessionManager: sessionManager,
    ),
  );

  try {
    final loginSession = await authRepository.login(
      email: email,
      password: password,
    );
    sessionManager.applySession(loginSession);

    final firstPage = await expensesRepository.listExpenses();
    final refreshed = await sessionManager.refreshSession();
    if (!refreshed) {
      throw StateError('Refresh token falhou no smoke real.');
    }

    final secondPage = await expensesRepository.listExpenses();
    await sessionManager.clearSession();

    if (sessionManager.accessToken != null) {
      throw StateError('Logout local nao limpou a sessao.');
    }

    stdout.writeln('SMOKE_OK');
    stdout.writeln('baseUrl=$baseUrl');
    stdout.writeln('email=$email');
    stdout.writeln('firstFetch=${firstPage.items.length}');
    stdout.writeln('secondFetch=${secondPage.items.length}');
  } finally {
    httpClient.close();
  }
}

String _requiredEnv(String name) {
  final value = Platform.environment[name];
  if (value == null || value.trim().isEmpty) {
    throw StateError(
      'Variavel obrigatoria ausente para o smoke real: $name. Carregue o ambiente governado antes de executar.',
    );
  }
  return value.trim();
}

class _SmokeSessionManager implements SessionManager {
  _SmokeSessionManager({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;
  String? _accessToken;
  String? _refreshToken;

  @override
  String? get accessToken => _accessToken;

  void applySession(MobileSession session) {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
  }

  @override
  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return false;
    }

    final refreshedSession = await _authRepository.refresh(
      refreshToken: refreshToken,
    );
    applySession(refreshedSession);
    return true;
  }
}
