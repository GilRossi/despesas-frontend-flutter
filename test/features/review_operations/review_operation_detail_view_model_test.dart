import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('load populates review detail from repository', () async {
    final repository = FakeReviewOperationsRepository(
      detailResult: fakeReviewDetail(subject: 'Compra Cobasi'),
    );
    final viewModel = ReviewOperationDetailViewModel(
      ingestionId: 51,
      reviewOperationsRepository: repository,
    );

    await viewModel.load();

    expect(viewModel.detail?.subject, 'Compra Cobasi');
    expect(viewModel.errorMessage, isNull);
    expect(repository.detailCalls, 1);
  });

  test('load exposes not found state when backend returns 404', () async {
    final viewModel = ReviewOperationDetailViewModel(
      ingestionId: 99,
      reviewOperationsRepository: FakeReviewOperationsRepository(
        detailError: const ApiException(statusCode: 404, message: 'Nao achou'),
      ),
    );

    await viewModel.load();

    expect(viewModel.isNotFound, isTrue);
    expect(viewModel.detail, isNull);
  });

  test('approve exposes API message when action fails', () async {
    final repository = FakeReviewOperationsRepository(
      detailResult: fakeReviewDetail(),
      approveError: const ApiException(
        statusCode: 422,
        message: 'A ingestao selecionada nao esta mais pendente de revisao.',
      ),
    );
    final viewModel = ReviewOperationDetailViewModel(
      ingestionId: 51,
      reviewOperationsRepository: repository,
    );

    await viewModel.load();
    final result = await viewModel.approve();

    expect(result, isNull);
    expect(
      viewModel.actionErrorMessage,
      'A ingestao selecionada nao esta mais pendente de revisao.',
    );
  });
}
