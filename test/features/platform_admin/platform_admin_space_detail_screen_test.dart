import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_space_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1800);
    addTearDown(tester.view.reset);
  }

  Future<SessionController> loginAsPlatformAdmin() async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          role: 'PLATFORM_ADMIN',
          householdId: null,
          email: 'admin@local.invalid',
          name: 'Platform Admin',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );
    return sessionController;
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required SessionController sessionController,
    required FakePlatformAdminRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminSpaceDetailScreen(
          spaceId: 4,
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza o detalhe minimo do Espaco e os modulos reais', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(
      spaceDetail: PlatformAdminSpace(
        spaceId: 4,
        spaceName: 'Teste',
        createdAt: DateTime.utc(2026, 4, 1, 20, 23),
        updatedAt: DateTime.utc(2026, 4, 10, 20, 23),
        activeMembersCount: 2,
        owner: const PlatformAdminSpaceOwner(
          userId: 6,
          name: 'Teste Owner',
          email: 'teste@teste.com',
        ),
        modules: const [
          PlatformAdminSpaceModule(
            key: 'FINANCIAL',
            enabled: true,
            mandatory: true,
          ),
          PlatformAdminSpaceModule(
            key: 'DRIVER',
            enabled: false,
            mandatory: false,
          ),
        ],
      ),
    );

    await pumpDetail(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    expect(find.text('Detalhe do Espaço'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('platform-admin-space-detail-summary-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('platform-admin-space-detail-modules-section')),
      findsOneWidget,
    );
    expect(find.text('Resumo do Espaço'), findsOneWidget);
    expect(find.text('Módulos do Espaço'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Motorista'), findsOneWidget);
    expect(find.text('Obrigatório'), findsOneWidget);
    expect(find.text('Desligado'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(
            find.byKey(
              const ValueKey(
                'platform-admin-space-detail-module-switch-FINANCIAL',
              ),
            ),
          )
          .onChanged,
      isNull,
    );
    expect(repository.spaceDetailCalls, 1);
    expect(repository.lastRequestedSpaceId, 4);
  });

  testWidgets('permite habilitar o DRIVER e salvar os modulos do Espaco', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository();

    await pumpDetail(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('platform-admin-space-detail-module-switch-DRIVER'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-space-detail-save-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.updateModulesCalls, 1);
    expect(repository.lastUpdatedSpaceId, 4);
    expect(repository.lastEnabledModuleKeys, ['FINANCIAL', 'DRIVER']);
    expect(find.text('Módulos do Espaço atualizados.'), findsOneWidget);
    expect(find.text('Ligado'), findsOneWidget);
  });

  testWidgets('mostra erro inicial e permite tentar novamente', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(
      spaceDetailError: const ApiException(
        statusCode: 503,
        message: 'Falha ao carregar o detalhe.',
      ),
    );

    await pumpDetail(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    expect(find.text('Não foi possível carregar este Espaço.'), findsOneWidget);
    expect(find.text('Falha ao carregar o detalhe.'), findsOneWidget);

    repository.spaceDetailError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('platform-admin-space-detail-summary-section')),
      findsOneWidget,
    );
    expect(repository.spaceDetailCalls, 2);
  });
}
