import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/foundation.dart';

class SpaceReferencesViewModel extends ChangeNotifier {
  SpaceReferencesViewModel({required SpaceReferencesRepository repository})
    : _repository = repository;

  final SpaceReferencesRepository _repository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  int? _loadErrorStatusCode;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<SpaceReferenceItem> _references = const [];
  SpaceReferenceTypeGroup? _selectedTypeGroup;
  String _query = '';
  SpaceReferenceItem? _selectedReference;
  SpaceReferenceCreateResult? _lastCreateResult;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  bool get isUnauthorized => _loadErrorStatusCode == 401;
  bool get isEmpty =>
      !_isLoading && _loadErrorMessage == null && _references.isEmpty;
  List<SpaceReferenceItem> get references => List.unmodifiable(_references);
  SpaceReferenceTypeGroup? get selectedTypeGroup => _selectedTypeGroup;
  String get query => _query;
  SpaceReferenceItem? get selectedReference => _selectedReference;
  SpaceReferenceCreateResult? get lastCreateResult => _lastCreateResult;

  String? fieldError(String field) => _fieldErrors[field];

  Future<void> load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    _loadErrorStatusCode = null;
    notifyListeners();

    try {
      _references = await _repository.listReferences(
        typeGroup: _selectedTypeGroup,
        query: _query,
      );
    } on ApiException catch (error) {
      _loadErrorMessage = error.message;
      _loadErrorStatusCode = error.statusCode;
    } catch (_) {
      _loadErrorMessage = 'Nao foi possivel carregar as referencias agora.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    required SpaceReferenceTypeGroup? typeGroup,
    required String query,
  }) async {
    _selectedTypeGroup = typeGroup;
    _query = query.trim();
    await load();
  }

  Future<void> clearFilters() async {
    _selectedTypeGroup = null;
    _query = '';
    await load();
  }

  Future<SpaceReferenceCreateResult?> createReference(
    CreateSpaceReferenceInput input,
  ) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    _lastCreateResult = null;
    notifyListeners();

    try {
      final result = await _repository.createReference(input);
      _lastCreateResult = result;

      if (result.reference != null) {
        _selectedReference = result.reference;
        _selectedTypeGroup = result.reference!.typeGroup;
        _query = '';
      } else if (result.suggestedReference != null) {
        _selectedTypeGroup = result.suggestedReference!.typeGroup;
        _query = '';
      }

      await load();
      return result;
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Nao foi possivel salvar a referencia agora.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void selectReference(SpaceReferenceItem reference) {
    _selectedReference = reference;
    notifyListeners();
  }

  void useSuggestedReference() {
    final suggestion = _lastCreateResult?.suggestedReference;
    if (suggestion == null) {
      return;
    }
    _selectedReference = suggestion;
    _lastCreateResult = null;
    notifyListeners();
  }
}
