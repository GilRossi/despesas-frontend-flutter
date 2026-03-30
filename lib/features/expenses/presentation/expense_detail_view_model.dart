import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
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
  bool _isSubmittingPayment = false;
  int? _removingPaymentId;
  String? _errorMessage;
  String? _paymentErrorMessage;
  ExpenseDetail? _expense;

  bool get isLoading => _isLoading;
  bool get isNotFound => _isNotFound;
  bool get isSubmittingPayment => _isSubmittingPayment;
  int? get removingPaymentId => _removingPaymentId;
  String? get errorMessage => _errorMessage;
  String? get paymentErrorMessage => _paymentErrorMessage;
  ExpenseDetail? get expense => _expense;
  bool get hasError => !_isNotFound && _errorMessage != null;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _isNotFound = false;
    _errorMessage = null;

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

  Future<bool> registerPayment(CreateExpensePaymentInput input) async {
    _isSubmittingPayment = true;
    _paymentErrorMessage = null;
    notifyListeners();

    try {
      await _expensesRepository.registerExpensePayment(input);
      _expense = await _expensesRepository.getExpenseDetail(_expenseId);
      _isNotFound = false;
      _errorMessage = null;
      return true;
    } on ApiException catch (error) {
      _paymentErrorMessage = error.message;
      return false;
    } catch (_) {
      _paymentErrorMessage = 'Nao foi possivel registrar o pagamento.';
      return false;
    } finally {
      _isSubmittingPayment = false;
      notifyListeners();
    }
  }

  Future<bool> deletePayment(int paymentId) async {
    _removingPaymentId = paymentId;
    _paymentErrorMessage = null;
    notifyListeners();

    try {
      await _expensesRepository.deleteExpensePayment(paymentId);
      _expense = await _expensesRepository.getExpenseDetail(_expenseId);
      _isNotFound = false;
      _errorMessage = null;
      return true;
    } on ApiException catch (error) {
      _paymentErrorMessage = error.message;
      return false;
    } catch (_) {
      _paymentErrorMessage = 'Nao foi possivel remover o pagamento.';
      return false;
    } finally {
      _removingPaymentId = null;
      notifyListeners();
    }
  }
}
