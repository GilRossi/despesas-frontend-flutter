import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';

class HttpReviewOperationsRepository implements ReviewOperationsRepository {
  HttpReviewOperationsRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<PagedResult<EmailIngestionReviewSummary>> listPendingReviews({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/email-ingestion/reviews',
        headers: headers,
        queryParameters: {
          'status': 'PENDING',
          'page': '$page',
          'size': '$size',
        },
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (decoded['content'] as List<dynamic>? ?? const [])
        .map(
          (item) => EmailIngestionReviewSummary.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
    final pageData = decoded['page'] as Map<String, dynamic>;

    return PagedResult(
      items: content,
      page: pageData['page'] as int,
      size: pageData['size'] as int,
      totalElements: pageData['totalElements'] as int,
      totalPages: pageData['totalPages'] as int,
      hasNext: pageData['hasNext'] as bool,
      hasPrevious: pageData['hasPrevious'] as bool,
    );
  }

  @override
  Future<EmailIngestionReviewDetail> getReviewDetail(int ingestionId) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/email-ingestion/reviews/$ingestionId',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return EmailIngestionReviewDetail.fromJson(data);
  }

  @override
  Future<EmailIngestionReviewActionResult> approveReview(
    int ingestionId,
  ) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/email-ingestion/reviews/$ingestionId/approve',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return EmailIngestionReviewActionResult.fromJson(data);
  }

  @override
  Future<EmailIngestionReviewActionResult> rejectReview(int ingestionId) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/email-ingestion/reviews/$ingestionId/reject',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return EmailIngestionReviewActionResult.fromJson(data);
  }
}
