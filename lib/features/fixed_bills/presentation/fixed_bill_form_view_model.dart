import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/foundation.dart';

class FixedBillFormViewModel extends ChangeNotifier {
  FixedBillFormViewModel({
    required FixedBillsRepository fixedBillsRepository,
    required ExpensesRepository expensesRepository,
    required SpaceReferencesRepository spaceReferencesRepository,
  }) : _fixedBillsRepository = fixedBillsRepository,
       _expensesRepository = expensesRepository,
       _spaceReferencesRepository = spaceReferencesRepository;

  final FixedBillsRepository _fixedBillsRepository;
  final ExpensesRepository _expensesRepository;
  final SpaceReferencesRepository _spaceReferencesRepository;

  bool _isLoadingCatalog = false;
  bool _isLoadingReferences = false;
  bool _isSubmitting = false;
  String? _loadCatalogErrorMessage;
  String? _loadReferencesErrorMessage;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<CatalogOption> _catalogOptions = const [];
  List<SpaceReferenceItem> _references = const [];

  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingReferences => _isLoadingReferences;
  bool get isSubmitting => _isSubmitting;
  String? get loadCatalogErrorMessage => _loadCatalogErrorMessage;
  String? get loadReferencesErrorMessage => _loadReferencesErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  bool get hasCatalogOptions => _catalogOptions.isNotEmpty;
  bool get hasFieldErrors => _fieldErrors.isNotEmpty;
  List<CatalogOption> get catalogOptions => List.unmodifiable(_catalogOptions);
  List<SpaceReferenceItem> get references => List.unmodifiable(_references);

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
          'Nao foi possivel carregar o catalogo para contas fixas agora.';
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> loadReferences() async {
    _isLoadingReferences = true;
    _loadReferencesErrorMessage = null;
    notifyListeners();

    try {
      _references = await _spaceReferencesRepository.listReferences();
    } on ApiException catch (error) {
      _loadReferencesErrorMessage = error.message;
    } catch (_) {
      _loadReferencesErrorMessage =
          'Nao foi possivel carregar as referencias do seu Espaco agora.';
    } finally {
      _isLoadingReferences = false;
      notifyListeners();
    }
  }

  Future<FixedBillRecord?> createFixedBill(CreateFixedBillInput input) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      return await _fixedBillsRepository.createFixedBill(input);
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Nao foi possivel cadastrar a conta fixa agora.';
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
