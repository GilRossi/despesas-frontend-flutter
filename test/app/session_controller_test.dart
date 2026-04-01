import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_doubles.dart';

void main() {
  test('login stores refresh token and authenticates the user', () async {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(refreshToken: 'stored-refresh-token'),
    );
    final sessionStore = MemorySessionStore();
    final controller = SessionController(
      authRepository: authRepository,
      sessionStore: sessionStore,
    );

    final success = await controller.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );

    expect(success, isTrue);
    expect(controller.status, SessionStatus.authenticated);
    expect(controller.currentUser?.email, 'gil@example.com');
    expect(sessionStore.refreshToken, 'stored-refresh-token');
  });

  test('restoreSession refreshes from stored token on startup', () async {
    final authRepository = FakeAuthRepository(
      refreshResult: fakeSession(refreshToken: 'new-refresh-token'),
    );
    final sessionStore = MemorySessionStore()..refreshToken = 'persisted-token';
    final controller = SessionController(
      authRepository: authRepository,
      sessionStore: sessionStore,
    );

    await controller.restoreSession();

    expect(controller.status, SessionStatus.authenticated);
    expect(authRepository.refreshCalls, 1);
    expect(sessionStore.refreshToken, 'new-refresh-token');
  });

  test(
    'login stays authenticated when refresh token persistence fails',
    () async {
      final authRepository = FakeAuthRepository(
        loginResult: fakeSession(refreshToken: 'stored-refresh-token'),
      );
      final sessionStore = ThrowingSessionStore(
        writeError: Exception('storage unavailable'),
      );
      final controller = SessionController(
        authRepository: authRepository,
        sessionStore: sessionStore,
      );

      final success = await controller.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );

      expect(success, isTrue);
      expect(controller.status, SessionStatus.authenticated);
      expect(controller.currentUser?.email, 'gil@example.com');
    },
  );

  test(
    'restoreSession falls back to unauthenticated when session store read fails',
    () async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(),
        sessionStore: ThrowingSessionStore(
          readError: Exception('storage unavailable'),
        ),
      );

      await controller.restoreSession();

      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.currentUser, isNull);
    },
  );

  test(
    'refreshSession falls back to false when session store read fails',
    () async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(),
        sessionStore: ThrowingSessionStore(
          readError: Exception('storage unavailable'),
        ),
      );

      final refreshed = await controller.refreshSession();

      expect(refreshed, isFalse);
      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.currentUser, isNull);
    },
  );

  test(
    'refreshSession clears the session when the refresh token is invalid',
    () async {
      final authRepository = FakeAuthRepository(refreshError: Exception('401'));
      final sessionStore = MemorySessionStore()..refreshToken = 'persisted';
      final controller = SessionController(
        authRepository: authRepository,
        sessionStore: sessionStore,
      );

      final refreshed = await controller.refreshSession();

      expect(refreshed, isFalse);
      expect(controller.status, SessionStatus.unauthenticated);
      expect(sessionStore.refreshToken, isNull);
      expect(sessionStore.cleared, isTrue);
    },
  );

  test(
    'login surfaces backend failure and resets to unauthenticated',
    () async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(
          loginError: Exception('invalid credentials'),
        ),
        sessionStore: MemorySessionStore(),
      );

      final success = await controller.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );

      expect(success, isFalse);
      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.errorMessage, 'Nao foi possivel fazer login agora.');
      expect(controller.isSubmitting, isFalse);
    },
  );

  test('logout clears the stored refresh token and session state', () async {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(refreshToken: 'stored'),
    );
    final sessionStore = MemorySessionStore()..refreshToken = 'persisted';
    final controller = SessionController(
      authRepository: authRepository,
      sessionStore: sessionStore,
    );

    await controller.login(email: 'gil@example.com', password: 'Senha123!');
    await controller.logout();

    expect(authRepository.logoutCalls, 1);
    expect(authRepository.lastLogoutRefreshToken, 'stored');
    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(sessionStore.refreshToken, isNull);
    expect(sessionStore.cleared, isTrue);
  });

  test(
    'logout still clears local session when backend revocation fails',
    () async {
      final sessionStore = MemorySessionStore()..refreshToken = 'persisted';
      final controller = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(refreshToken: 'stored'),
          logoutError: Exception('temporary failure'),
        ),
        sessionStore: sessionStore,
      );

      await controller.login(email: 'gil@example.com', password: 'Senha123!');
      await controller.logout();

      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.currentUser, isNull);
      expect(sessionStore.refreshToken, isNull);
      expect(sessionStore.cleared, isTrue);
    },
  );

  test('changeOwnPassword delegates to auth repository', () async {
    final authRepository = FakeAuthRepository();
    final controller = SessionController(
      authRepository: authRepository,
      sessionStore: MemorySessionStore(),
    );

    final result = await controller.changeOwnPassword(
      currentPassword: 'SenhaAtual123',
      newPassword: 'SenhaNova456',
      newPasswordConfirmation: 'SenhaNova456',
    );

    expect(authRepository.changePasswordCalls, 1);
    expect(authRepository.lastCurrentPassword, 'SenhaAtual123');
    expect(authRepository.lastNewPassword, 'SenhaNova456');
    expect(result.reauthenticationRequired, isTrue);
  });

  test(
    'requiresOnboarding is true for authenticated household users',
    () async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: false),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );

      await controller.login(email: 'gil@example.com', password: 'Senha123!');

      expect(controller.requiresOnboarding, isTrue);
    },
  );

  test('completeOnboarding updates the local session state', () async {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(
        onboarding: const AuthOnboarding(completed: false),
      ),
      completeOnboardingResult: AuthOnboarding(
        completed: true,
        completedAt: DateTime.utc(2026, 3, 28, 14),
      ),
      currentUserResult: const AuthUser(
        userId: 1,
        householdId: 10,
        email: 'gil@example.com',
        name: 'Gil Rossi',
        role: 'OWNER',
        onboarding: AuthOnboarding(completed: true),
      ),
    );
    final controller = SessionController(
      authRepository: authRepository,
      sessionStore: MemorySessionStore(),
    );

    await controller.login(email: 'gil@example.com', password: 'Senha123!');
    final onboarding = await controller.completeOnboarding();

    expect(authRepository.completeOnboardingCalls, 1);
    expect(authRepository.fetchCurrentUserCalls, 1);
    expect(onboarding.completed, isTrue);
    expect(controller.currentUser?.onboarding.completed, isTrue);
    expect(controller.requiresOnboarding, isFalse);
  });

  test(
    'completeOnboarding keeps authoritative state when auth/me fails',
    () async {
      final authRepository = FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        ),
        completeOnboardingResult: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 15),
        ),
        fetchCurrentUserError: Exception('temporary failure'),
      );
      final controller = SessionController(
        authRepository: authRepository,
        sessionStore: MemorySessionStore(),
      );

      await controller.login(email: 'gil@example.com', password: 'Senha123!');
      await controller.completeOnboarding();

      expect(controller.currentUser?.onboarding.completed, isTrue);
      expect(controller.currentUser?.onboarding.completedAt, isNotNull);
    },
  );
}
