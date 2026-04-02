import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/domain/income_record.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/foundation.dart';

class IncomeFormViewModel extends ChangeNotifier {
  IncomeFormViewModel({
    required IncomesRepository incomesRepository,
    required SpaceReferencesRepository spaceReferencesRepository,
  }) : _incomesRepository = incomesRepository,
       _spaceReferencesRepository = spaceReferencesRepository;

  final IncomesRepository _incomesRepository;
  final SpaceReferencesRepository _spaceReferencesRepository;

  bool _isLoadingReferences = false;
  bool _isSubmitting = false;
  String? _loadReferencesErrorMessage;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<SpaceReferenceItem> _references = const [];

  bool get isLoadingReferences => _isLoadingReferences;
  bool get isSubmitting => _isSubmitting;
  String? get loadReferencesErrorMessage => _loadReferencesErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  List<SpaceReferenceItem> get references => List.unmodifiable(_references);
  bool get hasFieldErrors => _fieldErrors.isNotEmpty;

  String? fieldError(String field) => _fieldErrors[field];

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
          'Não foi possível carregar as referências do seu espaço agora.';
    } finally {
      _isLoadingReferences = false;
      notifyListeners();
    }
  }

  Future<IncomeRecord?> createIncome(CreateIncomeInput input) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      return await _incomesRepository.createIncome(input);
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Não foi possível registrar o ganho agora.';
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
