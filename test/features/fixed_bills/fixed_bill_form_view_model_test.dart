import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('loadCatalogOptions and loadReferences populate available data', () async {
    final expensesRepository = FakeExpensesRepository(
      catalogOptions: fakeCatalogOptions(),
    );
    final spaceReferencesRepository = FakeSpaceReferencesRepository(
      references: [fakeSpaceReferenceItem(name: 'Projeto Horizonte')],
    );
    final viewModel = FixedBillFormViewModel(
      fixedBillsRepository: FakeFixedBillsRepository(),
      expensesRepository: expensesRepository,
      spaceReferencesRepository: spaceReferencesRepository,
    );

    await viewModel.loadCatalogOptions();
    await viewModel.loadReferences();

    expect(viewModel.hasCatalogOptions, isTrue);
    expect(viewModel.catalogOptions, isNotEmpty);
    expect(viewModel.references.single.name, 'Projeto Horizonte');
    expect(viewModel.loadCatalogErrorMessage, isNull);
    expect(viewModel.loadReferencesErrorMessage, isNull);
  });

  test('load methods expose generic fallback messages when repositories fail', () async {
    final viewModel = FixedBillFormViewModel(
      fixedBillsRepository: FakeFixedBillsRepository(),
      expensesRepository: FakeExpensesRepository(
        catalogError: Exception('boom'),
      ),
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        listError: Exception('boom'),
      ),
    );

    await viewModel.loadCatalogOptions();
    await viewModel.loadReferences();

    expect(
      viewModel.loadCatalogErrorMessage,
      'Nao foi possivel carregar o catalogo para contas fixas agora.',
    );
    expect(
      viewModel.loadReferencesErrorMessage,
      'Nao foi possivel carregar as referencias do seu Espaco agora.',
    );
  });

  test('createFixedBill returns the created record and clears feedback', () async {
    final repository = FakeFixedBillsRepository();
    final viewModel = FixedBillFormViewModel(
      fixedBillsRepository: repository,
      expensesRepository: FakeExpensesRepository(),
      spaceReferencesRepository: FakeSpaceReferencesRepository(),
    );
    final input = CreateFixedBillInput(
      description: 'Internet fibra',
      amount: 129.9,
      firstDueDate: DateTime(2026, 3, 10),
      frequency: FixedBillFrequency.monthly,
      context: 'HOME',
      categoryId: 1,
      subcategoryId: 2,
      spaceReferenceId: 7,
    );

    final result = await viewModel.createFixedBill(input);
    viewModel.clearFieldError('description');
    viewModel.clearSubmissionFeedback();

    expect(repository.createCalls, 1);
    expect(result?.description, 'Internet fibra');
    expect(viewModel.submitErrorMessage, isNull);
    expect(viewModel.hasFieldErrors, isFalse);
    expect(
      input.toJson(),
      {
        'description': 'Internet fibra',
        'amount': 129.9,
        'firstDueDate': '2026-03-10',
        'frequency': 'MONTHLY',
        'context': 'HOME',
        'categoryId': 1,
        'subcategoryId': 2,
        'spaceReferenceId': 7,
      },
    );
  });

  test('createFixedBill exposes API messages and field errors', () async {
    final viewModel = FixedBillFormViewModel(
      fixedBillsRepository: FakeFixedBillsRepository(
        createError: const ApiException(
          statusCode: 422,
          message: 'Request validation failed',
          fieldErrors: {'description': 'Descricao obrigatoria.'},
        ),
      ),
      expensesRepository: FakeExpensesRepository(),
      spaceReferencesRepository: FakeSpaceReferencesRepository(),
    );

    final result = await viewModel.createFixedBill(
      CreateFixedBillInput(
        description: 'Internet fibra',
        amount: 129.9,
        firstDueDate: DateTime(2026, 3, 10),
        frequency: FixedBillFrequency.monthly,
        context: 'HOME',
        categoryId: 1,
        subcategoryId: 2,
      ),
    );

    expect(result, isNull);
    expect(viewModel.submitErrorMessage, 'Request validation failed');
    expect(viewModel.fieldError('description'), 'Descricao obrigatoria.');
    expect(viewModel.hasFieldErrors, isTrue);
  });
}
