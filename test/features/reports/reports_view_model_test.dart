import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/reports/presentation/reports_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('load populates monthly report snapshot', () async {
    final repository = FakeReportsRepository(snapshot: fakeReportsSnapshot());
    final viewModel = ReportsViewModel(reportsRepository: repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.snapshot, isNotNull);
    expect(viewModel.errorMessage, isNull);
  });

  test('load exposes api error message when reports fail', () async {
    final viewModel = ReportsViewModel(
      reportsRepository: FakeReportsRepository(
        error: const ApiException(statusCode: 422, message: 'Falha simulada'),
      ),
    );

    await viewModel.load();

    expect(viewModel.errorMessage, 'Falha simulada');
  });

  test(
    'load exposes a generic message when reports fail unexpectedly',
    () async {
      final viewModel = ReportsViewModel(
        reportsRepository: FakeReportsRepository(error: Exception('boom')),
      );

      await viewModel.load(showLoading: false);

      expect(
        viewModel.errorMessage,
        'Não foi possível carregar os relatórios.',
      );
      expect(viewModel.isLoading, isFalse);
    },
  );

  test('navigation helpers reload the report for the expected month', () async {
    final repository = FakeReportsRepository(snapshot: fakeReportsSnapshot());
    final viewModel = ReportsViewModel(reportsRepository: repository);

    await viewModel.load(
      referenceMonth: DateTime(2026, 3, 1),
      comparePrevious: true,
    );
    await viewModel.goToPreviousMonth();
    await viewModel.goToNextMonth();
    await viewModel.setComparePrevious(false);

    expect(repository.loadCalls, 4);
    expect(viewModel.referenceMonth, DateTime(2026, 3));
    expect(viewModel.comparePrevious, isFalse);
  });
}
