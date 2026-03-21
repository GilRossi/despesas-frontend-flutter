import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:flutter/foundation.dart';

class ExpenseDetailViewModel extends ChangeNotifier {
  ExpenseDetailViewModel({
    required int expenseId,
    required ExpensesRepository expensesRepository,
  }) : _expenseId = expenseId,
       _expensesRepository = expensesRepository;

  final int _expenseId;
  final ExpensesRepository _expensesRepository;

  bool _isLoading = false;
  bool _isNotFound = false;
  String? _errorMessage;
  ExpenseDetail? _expense;

  bool get isLoading => _isLoading;
  bool get isNotFound => _isNotFound;
  String? get errorMessage => _errorMessage;
  ExpenseDetail? get expense => _expense;
  bool get hasError => !_isNotFound && _errorMessage != null;

  Future<void> load() async {
    _isLoading = true;
    _isNotFound = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _expense = await _expensesRepository.getExpenseDetail(_expenseId);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _isNotFound = true;
        _expense = null;
      } else {
        _errorMessage = error.message;
      }
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar o detalhe da despesa.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
