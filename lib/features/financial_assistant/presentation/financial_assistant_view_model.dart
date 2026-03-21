import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_conversation_entry.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:flutter/foundation.dart';

class FinancialAssistantViewModel extends ChangeNotifier {
  FinancialAssistantViewModel({
    required FinancialAssistantRepository financialAssistantRepository,
    DateTime? initialReferenceMonth,
  }) : _financialAssistantRepository = financialAssistantRepository,
       _referenceMonth = DateTime(
         initialReferenceMonth?.year ?? 2026,
         initialReferenceMonth?.month ?? 3,
       );

  final FinancialAssistantRepository _financialAssistantRepository;

  bool _isLoading = false;
  String? _errorMessage;
  int? _errorStatusCode;
  DateTime _referenceMonth;
  String? _lastQuestion;
  final List<FinancialAssistantConversationEntry> _entries = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _errorStatusCode == 401;
  DateTime get referenceMonth => _referenceMonth;
  List<FinancialAssistantConversationEntry> get entries =>
      List.unmodifiable(_entries);
  bool get hasConversation => _entries.isNotEmpty;

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
      _errorMessage = 'Nao foi possivel consultar o assistente financeiro.';
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

  Future<void> goToPreviousMonth() async {
    _referenceMonth = DateTime(_referenceMonth.year, _referenceMonth.month - 1);
    notifyListeners();
  }

  Future<void> goToNextMonth() async {
    _referenceMonth = DateTime(_referenceMonth.year, _referenceMonth.month + 1);
    notifyListeners();
  }
}
