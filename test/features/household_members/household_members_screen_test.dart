import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/household_members/presentation/household_members_screen.dart';
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

  testWidgets('shows current household members', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdMembersScreen(
          householdMembersRepository: FakeHouseholdMembersRepository(
            members: [
              fakeHouseholdMember(name: 'Gil Rossi', role: 'OWNER'),
              fakeHouseholdMember(
                id: 2,
                userId: 2,
                name: 'Bia Rossi',
                email: 'bia@example.com',
                role: 'MEMBER',
              ),
            ],
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Membros atuais'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gil Rossi', skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Gil Rossi'), findsOneWidget);
    expect(find.text('Bia Rossi'), findsOneWidget);
    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('Convidado'), findsOneWidget);
  });

  testWidgets('submits a new member from the minimal form', (tester) async {
    final repository = FakeHouseholdMembersRepository(
      members: [fakeHouseholdMember()],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdMembersScreen(
          householdMembersRepository: repository,
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Bia Rossi');
    await tester.enterText(find.byType(TextFormField).at(1), 'bia@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Senha123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar membro'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('bia@example.com', skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
      find.text('Membro criado. O novo login já pode usar a tela oficial.'),
      findsOneWidget,
    );
    expect(find.text('bia@example.com'), findsOneWidget);
  });

  testWidgets('shows access denied state for non-owner response', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdMembersScreen(
          householdMembersRepository: FakeHouseholdMembersRepository(
            listError: const ApiException(
              statusCode: 403,
              message: 'Apenas owner pode acessar.',
            ),
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acesso restrito aos responsáveis'), findsOneWidget);
    expect(find.text('Apenas owner pode acessar.'), findsOneWidget);
  });

  testWidgets('remains stable on small heights', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdMembersScreen(
          householdMembersRepository: FakeHouseholdMembersRepository(),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Adicionar membro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FilledButton, 'Adicionar membro'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps household member cards stable on narrow widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HouseholdMembersScreen(
          householdMembersRepository: FakeHouseholdMembersRepository(
            members: [
              fakeHouseholdMember(
                name: 'Nome longo para validar viewport estreito',
                email: 'email.longo@example.com',
                role: 'OWNER',
              ),
            ],
          ),
          sessionController: buildSessionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'Nome longo para validar viewport estreito',
        skipOffstage: false,
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nome longo para validar viewport estreito'),
      findsOneWidget,
    );
    expect(find.text('email.longo@example.com'), findsOneWidget);
    expect(find.text('Responsável'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
