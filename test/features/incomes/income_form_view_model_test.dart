import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/presentation/income_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test(
    'loadReferences populates data and toJson serializes the payload',
    () async {
      final repository = FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(name: 'Projeto Horizonte')],
      );
      final viewModel = IncomeFormViewModel(
        incomesRepository: FakeIncomesRepository(),
        spaceReferencesRepository: repository,
      );

      await viewModel.loadReferences();

      expect(viewModel.references.single.name, 'Projeto Horizonte');
      expect(viewModel.loadReferencesErrorMessage, isNull);
      expect(
        CreateIncomeInput(
          description: 'Salario',
          amount: 1500,
          receivedOn: DateTime(2026, 3, 5),
          spaceReferenceId: 7,
        ).toJson(),
        {
          'description': 'Salario',
          'amount': 1500,
          'receivedOn': '2026-03-05',
          'spaceReferenceId': 7,
        },
      );
    },
  );

  test('loadReferences and createIncome expose fallback errors', () async {
    final viewModel = IncomeFormViewModel(
      incomesRepository: FakeIncomesRepository(
        createError: const ApiException(
          statusCode: 422,
          message: 'Falha simulada',
          fieldErrors: {'description': 'Descricao obrigatoria.'},
        ),
      ),
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        listError: Exception('boom'),
      ),
    );

    await viewModel.loadReferences();
    expect(
      viewModel.loadReferencesErrorMessage,
      'Não foi possível carregar as referências do seu espaço agora.',
    );

    final result = await viewModel.createIncome(
      CreateIncomeInput(
        description: 'Salario',
        amount: 1500,
        receivedOn: DateTime(2026, 3, 5),
      ),
    );

    expect(result, isNull);
    expect(viewModel.submitErrorMessage, 'Falha simulada');
    expect(viewModel.fieldError('description'), 'Descricao obrigatoria.');
    viewModel.clearFieldError('description');
    viewModel.clearSubmissionFeedback();
    expect(viewModel.hasFieldErrors, isFalse);
    expect(viewModel.submitErrorMessage, isNull);
  });

  test(
    'createIncome returns the created record and balances loading state',
    () async {
      final repository = FakeIncomesRepository(
        createResult: fakeIncomeRecord(description: 'Salario', amount: 1500),
      );
      final viewModel = IncomeFormViewModel(
        incomesRepository: repository,
        spaceReferencesRepository: FakeSpaceReferencesRepository(),
      );

      final result = await viewModel.createIncome(
        CreateIncomeInput(
          description: 'Salario',
          amount: 1500,
          receivedOn: DateTime(2026, 3, 5),
        ),
      );

      expect(repository.createCalls, 1);
      expect(result?.description, 'Salario');
      expect(viewModel.isSubmitting, isFalse);
    },
  );
}
