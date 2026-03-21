import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';

abstract interface class ReviewOperationsRepository {
  Future<PagedResult<EmailIngestionReviewSummary>> listPendingReviews({
    int page = 0,
    int size = 20,
  });

  Future<EmailIngestionReviewDetail> getReviewDetail(int ingestionId);

  Future<EmailIngestionReviewActionResult> approveReview(int ingestionId);

  Future<EmailIngestionReviewActionResult> rejectReview(int ingestionId);
}
