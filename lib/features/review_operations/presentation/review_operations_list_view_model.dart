import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/foundation.dart';

class ReviewOperationsListViewModel extends ChangeNotifier {
  ReviewOperationsListViewModel({
    required ReviewOperationsRepository reviewOperationsRepository,
  }) : _reviewOperationsRepository = reviewOperationsRepository;

  final ReviewOperationsRepository _reviewOperationsRepository;

  bool _isLoading = false;
  String? _errorMessage;
  int? _errorStatusCode;
  PagedResult<EmailIngestionReviewSummary> _page = const PagedResult(
    items: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    hasNext: false,
    hasPrevious: false,
  );

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isForbidden => _errorStatusCode == 403;
  bool get isUnauthorized => _errorStatusCode == 401;
  bool get isEmpty =>
      !_isLoading && _errorMessage == null && _page.items.isEmpty;
  List<EmailIngestionReviewSummary> get reviews => _page.items;
  int get currentPage => _page.page;
  int get totalPages => _page.totalPages;
  bool get hasNextPage => _page.hasNext;
  bool get hasPreviousPage => _page.hasPrevious;
  int get totalElements => _page.totalElements;

  Future<void> load({int page = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      _page = await _reviewOperationsRepository.listPendingReviews(page: page);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _errorStatusCode = error.statusCode;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar as revisões pendentes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || _isLoading) {
      return;
    }
    await load(page: currentPage + 1);
  }

  Future<void> loadPreviousPage() async {
    if (!hasPreviousPage || _isLoading) {
      return;
    }
    await load(page: currentPage - 1);
  }
}
