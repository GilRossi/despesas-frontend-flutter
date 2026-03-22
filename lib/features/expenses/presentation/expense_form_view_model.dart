import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:flutter/foundation.dart';

class ExpenseFormViewModel extends ChangeNotifier {
  ExpenseFormViewModel({required ExpensesRepository expensesRepository})
    : _expensesRepository = expensesRepository;

  final ExpensesRepository _expensesRepository;

  bool _isLoadingCatalog = false;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<CatalogOption> _catalogOptions = const [];

  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isSubmitting => _isSubmitting;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  List<CatalogOption> get catalogOptions => _catalogOptions;
  bool get hasCatalogOptions => _catalogOptions.isNotEmpty;
  String? fieldError(String field) => _fieldErrors[field];

  Future<void> loadCatalogOptions() async {
    _isLoadingCatalog = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _catalogOptions = await _expensesRepository.listCatalogOptions();
    } on ApiException catch (error) {
      _loadErrorMessage = error.message;
    } catch (_) {
      _loadErrorMessage =
          'Nao foi possivel carregar categorias e subcategorias.';
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<bool> createExpense(SaveExpenseInput input) async {
    return _submit(() => _expensesRepository.createExpense(input));
  }

  Future<bool> updateExpense({
    required int expenseId,
    required SaveExpenseInput input,
  }) async {
    return _submit(
      () =>
          _expensesRepository.updateExpense(expenseId: expenseId, input: input),
    );
  }

  void clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(field);
    notifyListeners();
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      await action();
      return true;
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } catch (_) {
      _submitErrorMessage = 'Nao foi possivel salvar a despesa.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
