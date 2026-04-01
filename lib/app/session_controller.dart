import 'dart:async';

import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/auth/domain/auth_user.dart';
import 'package:despesas_frontend/features/auth/domain/change_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/forgot_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/auth/domain/reset_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/session_store.dart';
import 'package:flutter/foundation.dart';

enum SessionStatus { bootstrapping, unauthenticated, authenticated }

class SessionController extends ChangeNotifier implements SessionManager {
  SessionController({
    required AuthRepository authRepository,
    required SessionStore sessionStore,
  }) : _authRepository = authRepository,
       _sessionStore = sessionStore;

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  MobileSession? _session;
  SessionStatus _status = SessionStatus.bootstrapping;
  bool _isSubmitting = false;
  String? _errorMessage;
  Future<bool>? _refreshInFlight;

  SessionStatus get status => _status;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AuthUser? get currentUser => _session?.user;
  bool get hasAuthenticatedUser => _session != null;
  bool get requiresOnboarding {
    final user = currentUser;
    if (user == null) {
      return false;
    }
    if (user.householdId == null || user.role == 'PLATFORM_ADMIN') {
      return false;
    }
    return user.needsOnboarding;
  }

  @override
  String? get accessToken => _session?.accessToken;

  Future<void> restoreSession() async {
    if (_status != SessionStatus.bootstrapping) {
      return;
    }

    final refreshToken = await _readStoredRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final restored = await _refreshWithToken(refreshToken);
    if (!restored) {
      _status = SessionStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _applySession(session);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Nao foi possivel fazer login agora.';
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  Future<bool> refreshSession() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final refreshToken =
        _session?.refreshToken ?? await _readStoredRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return false;
    }

    _refreshInFlight = _refreshWithToken(refreshToken);
    final refreshed = await _refreshInFlight!;
    _refreshInFlight = null;
    return refreshed;
  }

  Future<void> logout() async {
    final refreshToken =
        _session?.refreshToken ?? await _readStoredRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authRepository.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // Local logout must still complete even if backend revocation fails.
    } finally {
      await clearSession();
    }
  }

  Future<AuthOnboarding> completeOnboarding() async {
    final session = _session;
    final currentUser = session?.user;
    if (session == null || currentUser == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_UNAVAILABLE',
        message: 'A sessao nao esta disponivel.',
      );
    }

    final onboarding = await _authRepository.completeOnboarding();
    var nextUser = currentUser.copyWith(onboarding: onboarding);

    try {
      nextUser = await _authRepository.fetchCurrentUser();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        rethrow;
      }
    } catch (_) {
      // Preserve the authoritative onboarding state already returned.
    }

    _session = session.copyWith(
      user: nextUser.copyWith(onboarding: onboarding),
    );
    notifyListeners();
    return onboarding;
  }

  Future<ChangePasswordResult> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) {
    return _authRepository.changeOwnPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) {
    return _authRepository.forgotPassword(email: email);
  }

  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirmation,
  }) {
    return _authRepository.resetPassword(
      token: token,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
  }

  @override
  Future<void> clearSession() async {
    _session = null;
    _status = SessionStatus.unauthenticated;
    _errorMessage = null;
    await _clearStoredRefreshToken();
    notifyListeners();
  }

  Future<bool> _refreshWithToken(String refreshToken) async {
    try {
      final session = await _authRepository.refresh(refreshToken: refreshToken);
      await _applySession(session);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> _applySession(MobileSession session) async {
    _session = session;
    _status = SessionStatus.authenticated;
    _errorMessage = null;
    await _persistRefreshToken(session.refreshToken);
    notifyListeners();
  }

  Future<String?> _readStoredRefreshToken() async {
    try {
      return await _sessionStore.readRefreshToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistRefreshToken(String refreshToken) async {
    try {
      await _sessionStore.writeRefreshToken(refreshToken);
    } catch (_) {
      // Keep the in-memory authenticated session even if persistence fails.
    }
  }

  Future<void> _clearStoredRefreshToken() async {
    try {
      await _sessionStore.clear();
    } catch (_) {
      // Clearing persistence failure must not keep the in-memory session alive.
    }
  }
}
