import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/presentation/space_references_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_doubles.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeSpaceReferencesRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceReferencesScreen(spaceReferencesRepository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista referencias existentes primeiro ao abrir a rota', (
    tester,
  ) async {
    final repository = FakeSpaceReferencesRepository(
      references: [
        fakeSpaceReferenceItem(name: 'Projeto Acme'),
        fakeSpaceReferenceItem(
          id: 2,
          type: SpaceReferenceType.casa,
          name: 'Casa da Praia',
        ),
      ],
    );

    await pumpScreen(tester, repository: repository);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('space-reference-card-1')),
    );

    expect(repository.listCalls, 1);
    expect(find.text('Projeto Acme'), findsOneWidget);
    expect(find.text('Casa da Praia'), findsOneWidget);
    expect(find.text('Criar nova referência'), findsOneWidget);
  });

  testWidgets('filtrar e limpar filtros reabre a listagem original', (
    tester,
  ) async {
    final repository = FakeSpaceReferencesRepository(
      references: [
        fakeSpaceReferenceItem(name: 'Projeto Horizonte'),
        fakeSpaceReferenceItem(
          id: 2,
          type: SpaceReferenceType.casa,
          name: 'Casa da Praia',
        ),
      ],
    );

    await pumpScreen(tester, repository: repository);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('space-references-search-field')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('space-references-search-field')),
      'Horizonte',
    );
    await tester.tap(
      find.byKey(const ValueKey('space-references-apply-filters')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastQuery, 'Horizonte');
    expect(find.text('Projeto Horizonte'), findsOneWidget);
    expect(find.text('Casa da Praia'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('space-references-clear-filters')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastQuery, isEmpty);
    expect(find.text('Projeto Horizonte'), findsWidgets);
    expect(find.text('Casa da Praia'), findsWidgets);
  });

  testWidgets('mostra erro de carregamento e permite tentar novamente', (
    tester,
  ) async {
    final repository = FakeSpaceReferencesRepository(
      listError: fakeApiException(message: 'Falha ao carregar referencias.'),
    );

    await pumpScreen(tester, repository: repository);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 1);
    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.text('Tentar novamente'));
    expect(find.text('Tentar novamente'), findsOneWidget);

    repository.listError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(find.text('Criar nova referência'), findsWidgets);
  });

  testWidgets('criacao guiada minima trata CREATED e atualiza a selecao', (
    tester,
  ) async {
    final repository = FakeSpaceReferencesRepository(references: const []);

    await pumpScreen(tester, repository: repository);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('space-references-name-field')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('space-references-name-field')),
      'Projeto Horizonte',
    );
    await tester.tap(
      find.byKey(const ValueKey('space-references-submit-button')),
    );
    await tester.pumpAndSettle();
    await scrollToTop(tester);

    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.name, 'Projeto Horizonte');
    expect(find.text('Referência em uso agora'), findsOneWidget);
    expect(find.text('Projeto Horizonte'), findsWidgets);
  });

  testWidgets(
    'DUPLICATE_SUGGESTION mostra mensagem e permite usar a referencia sugerida',
    (tester) async {
      final suggested = fakeSpaceReferenceItem(name: 'Projeto Acme');
      final repository = FakeSpaceReferencesRepository(
        references: [suggested],
        createResult: fakeSpaceReferenceCreateResult(
          result: SpaceReferenceCreateResultType.duplicateSuggestion,
          suggestedReference: suggested,
          message:
              'Encontrei uma referência parecida no seu espaço. Quer usar esta para evitar duplicidade?',
        ),
      );

      await pumpScreen(tester, repository: repository);
      await scrollTo(
        tester,
        find.byKey(const ValueKey('space-references-name-field')),
      );

      await tester.enterText(
        find.byKey(const ValueKey('space-references-name-field')),
        'Projeto Acme',
      );
      await tester.tap(
        find.byKey(const ValueKey('space-references-submit-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('space-references-duplicate-card')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Encontrei uma referência parecida no seu espaço. Quer usar esta para evitar duplicidade?',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('space-references-use-suggested-button')),
      );
      await tester.pumpAndSettle();
      await scrollToTop(tester);

      expect(find.text('Referência em uso agora'), findsOneWidget);
      expect(find.text('Projeto Acme'), findsWidgets);
    },
  );

  testWidgets('header action returns to the assistant flow', (tester) async {
    final router = GoRouter(
      initialLocation: '/space/references',
      routes: [
        GoRoute(
          path: '/assistant',
          builder: (context, state) =>
              const Scaffold(body: Text('assistant-page')),
        ),
        GoRoute(
          path: '/space/references',
          builder: (context, state) => SpaceReferencesScreen(
            spaceReferencesRepository: FakeSpaceReferencesRepository(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('space-references-back-to-assistant')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('space-references-back-to-assistant')),
    );
    await tester.pumpAndSettle();

    expect(find.text('assistant-page'), findsOneWidget);
  });
}
