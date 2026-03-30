import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/foundation.dart';

class ExpenseFormViewModel extends ChangeNotifier {
  ExpenseFormViewModel({
    required ExpensesRepository expensesRepository,
    SpaceReferencesRepository? spaceReferencesRepository,
  }) : _expensesRepository = expensesRepository,
       _spaceReferencesRepository = spaceReferencesRepository;

  final ExpensesRepository _expensesRepository;
  final SpaceReferencesRepository? _spaceReferencesRepository;

  bool _isLoadingCatalog = false;
  bool _isLoadingReferences = false;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  String? _loadReferencesErrorMessage;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<CatalogOption> _catalogOptions = const [];
  List<SpaceReferenceItem> _references = const [];

  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingReferences => _isLoadingReferences;
  bool get isSubmitting => _isSubmitting;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get loadReferencesErrorMessage => _loadReferencesErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  List<CatalogOption> get catalogOptions => _catalogOptions;
  List<SpaceReferenceItem> get references => List.unmodifiable(_references);
  bool get hasCatalogOptions => _catalogOptions.isNotEmpty;
  bool get hasReferences => _references.isNotEmpty;
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

  Future<void> loadReferences() async {
    final repository = _spaceReferencesRepository;
    if (repository == null) {
      _references = const [];
      _loadReferencesErrorMessage = null;
      notifyListeners();
      return;
    }

    _isLoadingReferences = true;
    _loadReferencesErrorMessage = null;
    notifyListeners();

    try {
      _references = await repository.listReferences();
    } on ApiException catch (error) {
      _loadReferencesErrorMessage = error.message;
    } catch (_) {
      _loadReferencesErrorMessage =
          'Nao foi possivel carregar as referencias do seu Espaco.';
    } finally {
      _isLoadingReferences = false;
      notifyListeners();
    }
  }

  Future<ExpenseSummary?> createExpense(SaveExpenseInput input) async {
    return _submit(() => _expensesRepository.createExpense(input));
  }

  Future<bool> updateExpense({
    required int expenseId,
    required SaveExpenseInput input,
  }) async {
    final result = await _submit<bool>(() async {
      await _expensesRepository.updateExpense(expenseId: expenseId, input: input);
      return true;
    });
    return result ?? false;
  }

  void clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }

    _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(field);
    notifyListeners();
  }

  Future<T?> _submit<T>(Future<T> Function() action) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Nao foi possivel salvar a despesa.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
