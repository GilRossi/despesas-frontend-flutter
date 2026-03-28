import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/presentation/space_references_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Criar nova referencia'), findsOneWidget);
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
    expect(find.text('Referencia em uso agora'), findsOneWidget);
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
              'Encontrei uma referencia parecida no seu Espaco. Quer usar essa para evitar duplicidade?',
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
          'Encontrei uma referencia parecida no seu Espaco. Quer usar essa para evitar duplicidade?',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('space-references-use-suggested-button')),
      );
      await tester.pumpAndSettle();
      await scrollToTop(tester);

      expect(find.text('Referencia em uso agora'), findsOneWidget);
      expect(find.text('Projeto Acme'), findsWidgets);
    },
  );
}
