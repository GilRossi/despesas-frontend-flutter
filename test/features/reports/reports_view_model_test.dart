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
}
