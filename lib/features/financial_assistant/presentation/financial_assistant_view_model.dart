import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_conversation_entry.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_reply.dart';
import 'package:flutter/foundation.dart';

class FinancialAssistantViewModel extends ChangeNotifier {
  FinancialAssistantViewModel({
    required FinancialAssistantRepository financialAssistantRepository,
    required SessionController sessionController,
    DateTime? initialReferenceMonth,
    bool reopenTourOnStart = false,
  }) : _financialAssistantRepository = financialAssistantRepository,
       _sessionController = sessionController,
       _referenceMonth = DateTime(
         initialReferenceMonth?.year ?? 2026,
         initialReferenceMonth?.month ?? 3,
       ),
       _isTourVisible =
           sessionController.requiresOnboarding || reopenTourOnStart {
    _sessionController.addListener(_handleSessionChanged);
  }

  final FinancialAssistantRepository _financialAssistantRepository;
  final SessionController _sessionController;

  bool _isLoading = false;
  bool _isStarterLoading = false;
  bool _isCompletingOnboarding = false;
  bool _isTourVisible;
  String? _errorMessage;
  int? _errorStatusCode;
  String? _starterErrorMessage;
  int? _starterErrorStatusCode;
  String? _onboardingErrorMessage;
  DateTime _referenceMonth;
  String? _lastQuestion;
  FinancialAssistantStarterIntent? _lastStarterIntent;
  FinancialAssistantStarterReply? _starterReply;
  final List<FinancialAssistantConversationEntry> _entries = [];

  bool get isLoading => _isLoading;
  bool get isStarterLoading => _isStarterLoading;
  bool get isCompletingOnboarding => _isCompletingOnboarding;
  bool get isTourVisible => _isTourVisible;
  bool get showWelcome => _sessionController.requiresOnboarding;
  String? get errorMessage => _errorMessage;
  String? get starterErrorMessage => _starterErrorMessage;
  String? get onboardingErrorMessage => _onboardingErrorMessage;
  bool get isUnauthorized =>
      _errorStatusCode == 401 || _starterErrorStatusCode == 401;
  DateTime get referenceMonth => _referenceMonth;
  FinancialAssistantStarterReply? get starterReply => _starterReply;
  List<FinancialAssistantConversationEntry> get entries =>
      List.unmodifiable(_entries);
  List<FinancialAssistantStarterIntent> get starterOptions =>
      FinancialAssistantStarterIntent.values;
  bool get hasConversation => _entries.isNotEmpty;
  bool get showOfficialStarterState => !hasConversation;
  String get firstName {
    final name = _sessionController.currentUser?.name.trim();
    if (name == null || name.isEmpty) {
      return 'voce';
    }
    return name.split(' ').first;
  }

  Future<void> submitQuestion(String question) async {
    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _errorStatusCode = null;
    _lastQuestion = normalizedQuestion;
    notifyListeners();

    try {
      final reply = await _financialAssistantRepository.askQuestion(
        question: normalizedQuestion,
        referenceMonth: _referenceMonth,
      );
      _entries.add(
        FinancialAssistantConversationEntry(
          referenceMonth: _referenceMonth,
          reply: reply,
        ),
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _errorStatusCode = error.statusCode;
    } catch (_) {
      _errorMessage = 'Não foi possível consultar o assistente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLastQuestion() async {
    if (_lastQuestion == null || _lastQuestion!.isEmpty) {
      return;
    }
    await submitQuestion(_lastQuestion!);
  }

  Future<void> selectStarterIntent(
    FinancialAssistantStarterIntent intent,
  ) async {
    _isStarterLoading = true;
    _starterErrorMessage = null;
    _starterErrorStatusCode = null;
    _lastStarterIntent = intent;
    notifyListeners();

    try {
      _starterReply = await _financialAssistantRepository.fetchStarterIntent(
        intent: intent,
      );
    } on ApiException catch (error) {
      _starterErrorMessage = error.message;
      _starterErrorStatusCode = error.statusCode;
    } catch (_) {
      _starterErrorMessage = 'Não foi possível preparar essa próxima etapa.';
    } finally {
      _isStarterLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryStarterIntent() async {
    if (_lastStarterIntent == null) {
      return;
    }
    await selectStarterIntent(_lastStarterIntent!);
  }

  Future<void> completeOnboarding() async {
    if (!_sessionController.requiresOnboarding) {
      _isTourVisible = false;
      notifyListeners();
      return;
    }

    _isCompletingOnboarding = true;
    _onboardingErrorMessage = null;
    notifyListeners();

    try {
      await _sessionController.completeOnboarding();
      _isTourVisible = false;
    } on ApiException catch (error) {
      _onboardingErrorMessage = error.message;
    } catch (_) {
      _onboardingErrorMessage = 'Não foi possível concluir o guia.';
    } finally {
      _isCompletingOnboarding = false;
      notifyListeners();
    }
  }

  void reopenTour() {
    _isTourVisible = true;
    _onboardingErrorMessage = null;
    notifyListeners();
  }

  void dismissTour() {
    if (!_isTourVisible) {
      return;
    }
    _isTourVisible = false;
    notifyListeners();
  }

  Future<void> goToPreviousMonth() async {
    _referenceMonth = DateTime(_referenceMonth.year, _referenceMonth.month - 1);
    notifyListeners();
  }

  Future<void> goToNextMonth() async {
    _referenceMonth = DateTime(_referenceMonth.year, _referenceMonth.month + 1);
    notifyListeners();
  }

  void _handleSessionChanged() {
    if (!_sessionController.requiresOnboarding && _isTourVisible) {
      _isTourVisible = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionController.removeListener(_handleSessionChanged);
    super.dispose();
  }
}
