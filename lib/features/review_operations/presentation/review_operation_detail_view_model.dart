import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/foundation.dart';

class ReviewOperationDetailViewModel extends ChangeNotifier {
  ReviewOperationDetailViewModel({
    required int ingestionId,
    required ReviewOperationsRepository reviewOperationsRepository,
  }) : _ingestionId = ingestionId,
       _reviewOperationsRepository = reviewOperationsRepository;

  final int _ingestionId;
  final ReviewOperationsRepository _reviewOperationsRepository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isNotFound = false;
  String? _errorMessage;
  int? _errorStatusCode;
  String? _actionErrorMessage;
  EmailIngestionReviewDetail? _detail;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isNotFound => _isNotFound;
  bool get isForbidden => _errorStatusCode == 403;
  bool get isUnauthorized => _errorStatusCode == 401;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  EmailIngestionReviewDetail? get detail => _detail;
  bool get hasError => !_isNotFound && _errorMessage != null;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _isNotFound = false;
    _errorMessage = null;
    _errorStatusCode = null;

    try {
      _detail = await _reviewOperationsRepository.getReviewDetail(_ingestionId);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _isNotFound = true;
        _detail = null;
      } else {
        _errorMessage = error.message;
        _errorStatusCode = error.statusCode;
      }
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar o detalhe da revisao.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EmailIngestionReviewActionResult?> approve() {
    return _runAction((ingestionId) {
      return _reviewOperationsRepository.approveReview(ingestionId);
    });
  }

  Future<EmailIngestionReviewActionResult?> reject() {
    return _runAction((ingestionId) {
      return _reviewOperationsRepository.rejectReview(ingestionId);
    });
  }

  Future<EmailIngestionReviewActionResult?> _runAction(
    Future<EmailIngestionReviewActionResult> Function(int ingestionId) action,
  ) async {
    _isSubmitting = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      return await action(_ingestionId);
    } on ApiException catch (error) {
      _actionErrorMessage = error.message;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Nao foi possivel concluir a revisao.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
