import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:flutter/foundation.dart';

class HouseholdMembersViewModel extends ChangeNotifier {
  HouseholdMembersViewModel({
    required HouseholdMembersRepository householdMembersRepository,
  }) : _householdMembersRepository = householdMembersRepository;

  final HouseholdMembersRepository _householdMembersRepository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  int? _loadErrorStatusCode;
  String? _submitErrorMessage;
  Map<String, String> _fieldErrors = const {};
  List<HouseholdMember> _members = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  bool get isForbidden => _loadErrorStatusCode == 403;
  bool get isUnauthorized => _loadErrorStatusCode == 401;
  bool get isEmpty =>
      !_isLoading && _loadErrorMessage == null && _members.isEmpty;
  List<HouseholdMember> get members => _members;

  String? fieldError(String field) => _fieldErrors[field];

  Future<void> load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    _loadErrorStatusCode = null;
    notifyListeners();

    try {
      _members = await _householdMembersRepository.listMembers();
    } on ApiException catch (error) {
      _loadErrorMessage = error.message;
      _loadErrorStatusCode = error.statusCode;
    } catch (_) {
      _loadErrorMessage = 'Não foi possível carregar os membros do espaço.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMember(CreateHouseholdMemberInput input) async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      await _householdMembersRepository.createMember(input);
      await load();
      return true;
    } on ApiException catch (error) {
      _submitErrorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } catch (_) {
      _submitErrorMessage = 'Não foi possível adicionar o novo membro.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
