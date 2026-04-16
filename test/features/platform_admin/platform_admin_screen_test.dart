import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_health.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
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

  Future<void> pumpAdminScreen(
    WidgetTester tester, {
    required SessionController sessionController,
    required FakePlatformAdminRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders overview, spaces and health for platform admin', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(
      spaces: const [
        PlatformAdminSpace(
          spaceId: 4,
          spaceName: 'Teste',
          createdAt: null,
          updatedAt: null,
          activeMembersCount: 2,
          owner: PlatformAdminSpaceOwner(
            userId: 6,
            name: 'Teste Owner',
            email: 'teste@teste.com',
          ),
          modules: [
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
      ],
    );

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    expect(find.text('Admin da plataforma'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('platform-admin-overview-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('platform-admin-alerts-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('platform-admin-health-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('platform-admin-runtime-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('platform-admin-spaces-section')),
      findsOneWidget,
    );
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Alertas operacionais'), findsOneWidget);
    expect(find.text('Deploy e runtime'), findsOneWidget);
    expect(find.text('Saúde do sistema'), findsOneWidget);
    expect(find.text('Espaços'), findsWidgets);
    expect(find.text('Teste'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('Financeiro obrigatório'), findsOneWidget);
    expect(find.text('Motorista desligado'), findsOneWidget);
    expect(find.text('Abrir detalhe'), findsOneWidget);
    expect(find.text('UP'), findsAtLeastNWidgets(1));
    expect(find.text('Actuator metrics fechado'), findsWidgets);
    expect(find.text('0.0.1-SNAPSHOT'), findsOneWidget);
    expect(find.text('Aceitando tráfego'), findsOneWidget);
    expect(
      find.text(
        'As métricas do Actuator ainda não estão expostas por HTTP nesta fase.',
      ),
      findsOneWidget,
    );
    expect(find.text('Uso do heap'), findsOneWidget);
    expect(
      find.text(
        'Métricas HTTP ainda não expostas. O admin sinaliza esse limite como alerta operacional.',
      ),
      findsOneWidget,
    );
    expect(repository.overviewCalls, 1);
    expect(repository.healthCalls, 1);
    expect(repository.spacesCalls, 1);
  });

  testWidgets('shows neutral state when there are no operational alerts', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(
      health: PlatformAdminHealth(
        applicationStatus: 'UP',
        checkedAt: DateTime.utc(2026, 4, 15, 12, 10),
        actuator: const PlatformAdminActuatorExposure(
          healthExposed: true,
          infoExposed: true,
          metricsExposed: true,
        ),
        deployment: PlatformAdminDeploymentSnapshot(
          applicationName: 'despesas',
          artifact: 'despesas',
          version: null,
          builtAt: null,
        ),
        runtime: PlatformAdminRuntimeSnapshot(
          livenessState: 'CORRECT',
          readinessState: 'ACCEPTING_TRAFFIC',
          startedAt: DateTime.utc(2026, 4, 15, 12, 8),
        ),
        jvm: const PlatformAdminJvmSnapshot(
          availableProcessors: 4,
          uptimeMs: 120000,
          heapUsedBytes: 300,
          heapCommittedBytes: 600,
          heapMaxBytes: 1000,
        ),
        system: const PlatformAdminSystemSnapshot(systemLoadAverage: null),
        info: const {'build': '1.0.0'},
        alerts: const [],
      ),
    );

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    expect(find.text('Nenhum alerta operacional agora.'), findsOneWidget);
    expect(
      find.text(
        'As fontes atuais não apontam atenção imediata nesta leitura.',
      ),
      findsOneWidget,
    );
    expect(find.text('Versão do app'), findsOneWidget);
    expect(find.text('Indisponível'), findsWidgets);
    expect(find.text('Fonte atual não entrega esse dado'), findsNWidgets(2));
  });

  testWidgets('shows empty state when there are no spaces', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(spaces: const []);

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    expect(find.text('Nenhum Espaço cadastrado.'), findsOneWidget);
  });

  testWidgets('shows load error and retries admin data', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository(
      overviewError: fakeApiException(
        statusCode: 503,
        message: 'Falha ao carregar o admin.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar o admin agora.'),
      findsOneWidget,
    );
    expect(find.text('Falha ao carregar o admin.'), findsOneWidget);

    repository.overviewError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('platform-admin-overview-section')),
      findsOneWidget,
    );
    expect(repository.overviewCalls, 2);
  });

  testWidgets('submits space provisioning successfully', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository();

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do Espaço'),
      'Casa Controlada',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do responsável'),
      'Owner Controlado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail do responsável'),
      'owner@local.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha inicial do responsável'),
      'senha123',
    );

    final submitButton = find.widgetWithText(FilledButton, 'Criar Espaço');
    await tester.scrollUntilVisible(
      submitButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.text('Espaço criado com sucesso.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('platform-admin-last-provisioned-card')),
      findsOneWidget,
    );
  });

  testWidgets('opens self password change for platform admin', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: FakePlatformAdminRepository(),
    );

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-open-change-password-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('resets user password from the admin shell', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsPlatformAdmin();
    final repository = FakePlatformAdminRepository();

    await pumpAdminScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      'owner@local.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-new-password-field')),
      'NovaSenha456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-confirm-password-field')),
      'NovaSenha456',
    );

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-reset-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    expect(find.text('Senha resetada com sucesso.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('platform-admin-last-reset-card')),
      findsOneWidget,
    );
  });
}
