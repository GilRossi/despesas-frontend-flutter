import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';
import 'package:despesas_frontend/features/history_imports/presentation/history_import_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test(
    'loadCatalogOptions populates catalog data and input serialization works',
    () async {
      final repository = FakeExpensesRepository(
        catalogOptions: fakeCatalogOptions(),
      );
      final viewModel = HistoryImportFormViewModel(
        historyImportsRepository: FakeHistoryImportsRepository(),
        expensesRepository: repository,
      );

      await viewModel.loadCatalogOptions();

      expect(viewModel.hasCatalogOptions, isTrue);
      expect(viewModel.catalogOptions, isNotEmpty);
      expect(viewModel.loadCatalogErrorMessage, isNull);

      final input = CreateHistoryImportInput(
        paymentMethod: HistoryImportPaymentMethod.pix,
        entries: [
          HistoryImportEntryInput(
            description: 'Internet fibra',
            amount: 129.9,
            date: DateTime(2026, 3, 10, 14, 30),
            categoryId: 1,
            subcategoryId: 2,
            notes: '  Mensalidade  ',
          ),
        ],
      );

      expect(input.toJson(), {
        'paymentMethod': 'PIX',
        'entries': [
          {
            'description': 'Internet fibra',
            'amount': 129.9,
            'date': '2026-03-10',
            'categoryId': 1,
            'subcategoryId': 2,
            'notes': 'Mensalidade',
          },
        ],
      });
    },
  );

  test('loadCatalogOptions and importHistory expose error feedback', () async {
    final viewModel = HistoryImportFormViewModel(
      historyImportsRepository: FakeHistoryImportsRepository(
        importError: const ApiException(
          statusCode: 422,
          message: 'Falha simulada',
          fieldErrors: {'paymentMethod': 'Escolha um metodo.'},
        ),
      ),
      expensesRepository: FakeExpensesRepository(
        catalogError: Exception('boom'),
      ),
    );

    await viewModel.loadCatalogOptions();
    expect(
      viewModel.loadCatalogErrorMessage,
      'Não foi possível carregar o catálogo para importar seu histórico agora.',
    );

    final result = await viewModel.importHistory(
      CreateHistoryImportInput(
        paymentMethod: HistoryImportPaymentMethod.pix,
        entries: const [],
      ),
    );

    expect(result, isNull);
    expect(viewModel.submitErrorMessage, 'Falha simulada');
    expect(viewModel.fieldError('paymentMethod'), 'Escolha um metodo.');
    viewModel.clearFieldError('paymentMethod');
    viewModel.clearSubmissionFeedback();
    expect(viewModel.hasFieldErrors, isFalse);
    expect(viewModel.submitErrorMessage, isNull);
  });

  test(
    'importHistory returns the created result and keeps the loading flag balanced',
    () async {
      final repository = FakeHistoryImportsRepository(
        importResult: HistoryImportResult(
          importedCount: 1,
          entries: [
            fakeHistoryImportEntryRecord(description: 'Internet fibra'),
          ],
        ),
      );
      final viewModel = HistoryImportFormViewModel(
        historyImportsRepository: repository,
        expensesRepository: FakeExpensesRepository(),
      );

      final result = await viewModel.importHistory(
        CreateHistoryImportInput(
          paymentMethod: HistoryImportPaymentMethod.debito,
          entries: [
            HistoryImportEntryInput(
              description: 'Internet fibra',
              amount: 129.9,
              date: DateTime(2026, 3, 10),
              categoryId: 1,
              subcategoryId: 2,
            ),
          ],
        ),
      );

      expect(repository.importCalls, 1);
      expect(result?.importedCount, 1);
      expect(viewModel.isSubmitting, isFalse);
    },
  );
}
