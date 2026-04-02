import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';
import 'package:flutter/foundation.dart';

class HistoryImportFormViewModel extends ChangeNotifier {
  HistoryImportFormViewModel({
    required HistoryImportsRepository historyImportsRepository,
    required ExpensesRepository expensesRepository,
  }) : _historyImportsRepository = historyImportsRepository,
       _expensesRepository = expensesRepository;

  final HistoryImportsRepository _historyImportsRepository;
  final ExpensesRepository _expensesRepository;

  bool _isLoadingCatalog = false;
  bool _isSubmitting = false;
  String? _loadCatalogErrorMessage;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<CatalogOption> _catalogOptions = const [];

  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isSubmitting => _isSubmitting;
  String? get loadCatalogErrorMessage => _loadCatalogErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  bool get hasCatalogOptions => _catalogOptions.isNotEmpty;
  bool get hasFieldErrors => _fieldErrors.isNotEmpty;
  List<CatalogOption> get catalogOptions => List.unmodifiable(_catalogOptions);

  String? fieldError(String field) => _fieldErrors[field];

  Future<void> loadCatalogOptions() async {
    _isLoadingCatalog = true;
    _loadCatalogErrorMessage = null;
    notifyListeners();

    try {
      _catalogOptions = await _expensesRepository.listCatalogOptions();
    } on ApiException catch (error) {
      _loadCatalogErrorMessage = error.message;
    } catch (_) {
      _loadCatalogErrorMessage =
          'Não foi possível carregar o catálogo para importar seu histórico agora.';
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<HistoryImportResult?> importHistory(
    CreateHistoryImportInput input,
  ) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      return await _historyImportsRepository.importHistory(input);
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Não foi possível importar seu histórico agora.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(field);
    notifyListeners();
  }

  void clearSubmissionFeedback() {
    if (_submitErrorMessage == null && _fieldErrors.isEmpty) {
      return;
    }

    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
  }
}
