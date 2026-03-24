import 'package:despesas_frontend/app/session_controller.dart';
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
}
