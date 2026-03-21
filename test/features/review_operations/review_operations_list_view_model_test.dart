import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('load populates pending reviews from repository', () async {
    final repository = FakeReviewOperationsRepository(
      listResult: PagedResult(
        items: [fakeReviewSummary()],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      ),
    );
    final viewModel = ReviewOperationsListViewModel(
      reviewOperationsRepository: repository,
    );

    await viewModel.load();

    expect(repository.listCalls, 1);
    expect(viewModel.reviews, hasLength(1));
    expect(viewModel.errorMessage, isNull);
  });

  test('load exposes forbidden state when api returns 403', () async {
    final viewModel = ReviewOperationsListViewModel(
      reviewOperationsRepository: FakeReviewOperationsRepository(
        listError: const ApiException(
          statusCode: 403,
          message: 'Access denied',
        ),
      ),
    );

    await viewModel.load();

    expect(viewModel.isForbidden, isTrue);
    expect(viewModel.errorMessage, 'Access denied');
  });
}
