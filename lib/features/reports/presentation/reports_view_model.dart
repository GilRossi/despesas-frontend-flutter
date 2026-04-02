import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';
import 'package:flutter/foundation.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({required ReportsRepository reportsRepository})
    : _reportsRepository = reportsRepository;

  final ReportsRepository _reportsRepository;

  bool _isLoading = false;
  String? _errorMessage;
  int? _errorStatusCode;
  ReportsSnapshot? _snapshot;
  DateTime _referenceMonth = DateTime(2026, 3);
  bool _comparePrevious = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _errorStatusCode == 401;
  ReportsSnapshot? get snapshot => _snapshot;
  DateTime get referenceMonth => _referenceMonth;
  bool get comparePrevious => _comparePrevious;
  bool get hasData => _snapshot != null;

  Future<void> load({
    DateTime? referenceMonth,
    bool? comparePrevious,
    bool showLoading = true,
  }) async {
    if (referenceMonth != null) {
      _referenceMonth = DateTime(referenceMonth.year, referenceMonth.month);
    }
    if (comparePrevious != null) {
      _comparePrevious = comparePrevious;
    }

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _errorMessage = null;
    _errorStatusCode = null;

    try {
      _snapshot = await _reportsRepository.loadMonthlyReport(
        referenceMonth: _referenceMonth,
        comparePrevious: _comparePrevious,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _errorStatusCode = error.statusCode;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os relatórios.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPreviousMonth() {
    final previous = DateTime(_referenceMonth.year, _referenceMonth.month - 1);
    return load(referenceMonth: previous);
  }

  Future<void> goToNextMonth() {
    final next = DateTime(_referenceMonth.year, _referenceMonth.month + 1);
    return load(referenceMonth: next);
  }

  Future<void> setComparePrevious(bool value) {
    return load(comparePrevious: value);
  }
}
