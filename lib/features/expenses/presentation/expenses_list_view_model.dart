import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:flutter/foundation.dart';

class ExpensesListViewModel extends ChangeNotifier {
  ExpensesListViewModel({required ExpensesRepository expensesRepository})
    : _expensesRepository = expensesRepository;

  final ExpensesRepository _expensesRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<ExpenseSummary> _expenses = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExpenseSummary> get expenses => _expenses;
  bool get isEmpty => !_isLoading && _errorMessage == null && _expenses.isEmpty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _expensesRepository.listExpenses();
      _expenses = page.items;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar suas despesas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
