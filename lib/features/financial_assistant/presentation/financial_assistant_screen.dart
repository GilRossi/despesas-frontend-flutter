import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_conversation_entry.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_view_model.dart';
import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';
import 'package:flutter/material.dart';

class FinancialAssistantScreen extends StatefulWidget {
  const FinancialAssistantScreen({
    super.key,
    required this.financialAssistantRepository,
    required this.sessionController,
    this.onStarterPrimaryActionRequested,
  });

  final FinancialAssistantRepository financialAssistantRepository;
  final SessionController sessionController;
  final void Function(String primaryActionKey)? onStarterPrimaryActionRequested;

  @override
  State<FinancialAssistantScreen> createState() =>
      _FinancialAssistantScreenState();
}

class _FinancialAssistantScreenState extends State<FinancialAssistantScreen> {
  late final FinancialAssistantViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final _latestEntryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _viewModel = FinancialAssistantViewModel(
      financialAssistantRepository: widget.financialAssistantRepository,
      sessionController: widget.sessionController,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollToLatestEntry() {
    if (!mounted) {
      return;
    }

    final latestContext = _latestEntryKey.currentContext;
    if (latestContext != null) {
      Scrollable.ensureVisible(
        latestContext,
        alignment: 0.08,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final question = _questionController.text.trim();
    await _viewModel.submitQuestion(question);

    if (!mounted) {
      return;
    }

    if (_viewModel.errorMessage == null) {
      _questionController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLatestEntry();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return RoutePopScope<Object?>(
          fallbackRoute: '/',
          child: Scaffold(
            appBar: AppBar(
              leading: const RouteBackButton(fallbackRoute: '/'),
              title: const Text('Assistente financeiro'),
            ),
            body: SafeArea(
            top: false,
            child: ResponsiveScrollBody(
              controller: _scrollController,
              maxWidth: 1180,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(
                    firstName: _viewModel.firstName,
                    referenceMonth: _viewModel.referenceMonth,
                    isLoading: _viewModel.isLoading,
                    isTourVisible: _viewModel.isTourVisible,
                    showWelcome: _viewModel.showWelcome,
                    onPreviousMonth: _viewModel.goToPreviousMonth,
                    onNextMonth: _viewModel.goToNextMonth,
                    onReopenTour: _viewModel.reopenTour,
                  ),
                  const SizedBox(height: 16),
                  if (_viewModel.isTourVisible) ...[
                    _TourCard(
                      firstName: _viewModel.firstName,
                      isCompletingOnboarding: _viewModel.isCompletingOnboarding,
                      onDismiss: _viewModel.dismissTour,
                      onComplete: _viewModel.completeOnboarding,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_viewModel.onboardingErrorMessage != null) ...[
                    _InlineErrorCard(
                      title: 'Nao foi possivel concluir a apresentacao.',
                      message: _viewModel.onboardingErrorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _viewModel.completeOnboarding,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_viewModel.showOfficialStarterState) ...[
                    _OfficialStarterStateCard(
                      isLoading: _viewModel.isStarterLoading,
                      reply: _viewModel.starterReply,
                      options: _viewModel.starterOptions,
                      onSelectStarterIntent: _viewModel.selectStarterIntent,
                      onPrimaryActionRequested:
                          widget.onStarterPrimaryActionRequested,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_viewModel.starterErrorMessage != null) ...[
                    _InlineErrorCard(
                      title: _viewModel.isUnauthorized
                          ? 'Sessao expirada'
                          : 'Nao foi possivel preparar essa proxima etapa.',
                      message: _viewModel.starterErrorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _viewModel.retryStarterIntent,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _QuestionComposer(
                    formKey: _formKey,
                    controller: _questionController,
                    isLoading: _viewModel.isLoading,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 16),
                  if (_viewModel.errorMessage != null) ...[
                    _InlineErrorCard(
                      title: _viewModel.isUnauthorized
                          ? 'Sessao expirada'
                          : 'Nao foi possivel consultar o assistente.',
                      message: _viewModel.errorMessage!,
                      actionLabel: _viewModel.hasConversation
                          ? 'Tentar novamente'
                          : 'Reenviar ultima pergunta',
                      onAction: _viewModel.retryLastQuestion,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_viewModel.isLoading) ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Consultando o backend do assistente financeiro no household atual...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_viewModel.hasConversation)
                    for (
                      var index = 0;
                      index < _viewModel.entries.length;
                      index++
                    ) ...[
                      KeyedSubtree(
                        key: index == _viewModel.entries.length - 1
                            ? _latestEntryKey
                            : null,
                        child: _ConversationEntryCard(
                          entry: _viewModel.entries[index],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.firstName,
    required this.referenceMonth,
    required this.isLoading,
    required this.isTourVisible,
    required this.showWelcome,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onReopenTour,
  });

  final String firstName;
  final DateTime referenceMonth;
  final bool isLoading;
  final bool isTourVisible;
  final bool showWelcome;
  final Future<void> Function() onPreviousMonth;
  final Future<void> Function() onNextMonth;
  final VoidCallback onReopenTour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          spacing: 16,
          children: [
            SizedBox(
              width: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showWelcome
                        ? 'Bem-vindo ao seu Espaco, $firstName'
                        : 'Assistente financeiro do seu Espaco',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showWelcome
                        ? 'Voce chegou no ponto certo para comecar. O assistente te apresenta as primeiras escolhas e continua ao seu lado nas proximas conversas.'
                        : 'Escolha uma proxima etapa ou pergunte direto sobre gastos, comparacoes e recorrencias. O contexto financeiro continua vindo do backend.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF65727B),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : () => onPreviousMonth(),
                  child: const Text('Mes anterior'),
                ),
                FilledButton.tonal(
                  onPressed: null,
                  child: Text(_formatMonthLabel(referenceMonth)),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('assistant-reopen-tour-button'),
                  onPressed: isTourVisible ? null : onReopenTour,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Rever tour'),
                ),
                OutlinedButton(
                  onPressed: isLoading ? null : () => onNextMonth(),
                  child: const Text('Proximo mes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.firstName,
    required this.isCompletingOnboarding,
    required this.onDismiss,
    required this.onComplete,
  });

  final String firstName;
  final bool isCompletingOnboarding;
  final VoidCallback onDismiss;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('assistant-tour-card'),
      color: const Color(0xFFFFF6E8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Boas-vindas ao Espaco', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$firstName, este tour e curto e pratico. A ideia aqui e te mostrar por onde comecar sem te jogar numa tela fria.',
            ),
            const SizedBox(height: 16),
            const _TourStep(
              title: '1. Escolha o primeiro passo',
              message:
                  'As quatro opcoes abaixo representam os caminhos aprovados para o inicio do seu Espaco.',
            ),
            const SizedBox(height: 12),
            const _TourStep(
              title: '2. O assistente organiza a conversa',
              message:
                  'Ao tocar em uma opcao, o backend responde com a proxima orientacao estruturada sem executar nenhuma acao real ainda.',
            ),
            const SizedBox(height: 12),
            const _TourStep(
              title: '3. Depois disso, o fluxo segue normal',
              message:
                  'Quando voce concluir esta apresentacao, os proximos acessos deixam de abrir o tour automaticamente.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: isCompletingOnboarding ? null : onDismiss,
                  child: const Text('Agora nao'),
                ),
                FilledButton.icon(
                  key: const ValueKey('assistant-complete-onboarding-button'),
                  onPressed: isCompletingOnboarding ? null : () => onComplete(),
                  icon: isCompletingOnboarding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Concluir apresentacao'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TourStep extends StatelessWidget {
  const _TourStep({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE4B7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfficialStarterStateCard extends StatelessWidget {
  const _OfficialStarterStateCard({
    required this.isLoading,
    required this.reply,
    required this.options,
    required this.onSelectStarterIntent,
    required this.onPrimaryActionRequested,
  });

  final bool isLoading;
  final FinancialAssistantStarterReply? reply;
  final List<FinancialAssistantStarterIntent> options;
  final Future<void> Function(FinancialAssistantStarterIntent intent)
  onSelectStarterIntent;
  final void Function(String primaryActionKey)? onPrimaryActionRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comece pelo que faz mais sentido agora',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Estas quatro opcoes formam o estado oficial de entrada do assistente neste bloco. Escolha uma e eu trago a proxima orientacao sem executar a acao real ainda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in options)
                  _StarterOptionButton(
                    intent: option,
                    isLoading: isLoading,
                    onTap: onSelectStarterIntent,
                  ),
              ],
            ),
            if (reply != null) ...[
              const SizedBox(height: 16),
              _StarterReplyCard(
                reply: reply!,
                onPrimaryActionRequested: onPrimaryActionRequested,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarterOptionButton extends StatelessWidget {
  const _StarterOptionButton({
    required this.intent,
    required this.isLoading,
    required this.onTap,
  });

  final FinancialAssistantStarterIntent intent;
  final bool isLoading;
  final Future<void> Function(FinancialAssistantStarterIntent intent) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: FilledButton.tonal(
        key: ValueKey(
          'assistant-starter-${intent.apiValue.toLowerCase()}-button',
        ),
        onPressed: isLoading ? null : () => onTap(intent),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(intent.label),
            const SizedBox(height: 6),
            Text(
              intent.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterReplyCard extends StatelessWidget {
  const _StarterReplyCard({
    required this.reply,
    required this.onPrimaryActionRequested,
  });

  final FinancialAssistantStarterReply reply;
  final void Function(String primaryActionKey)? onPrimaryActionRequested;

  String? get _primaryActionLabel {
    switch (reply.primaryActionKey) {
      case 'OPEN_IMPORT_HISTORY':
        return 'Abrir importacao de historico';
      case 'OPEN_FIXED_BILLS':
        return 'Abrir cadastro de contas fixas';
      case 'OPEN_REGISTER_INCOME':
        return 'Abrir cadastro de ganhos';
      case 'OPEN_CONFIGURE_SPACE':
        return 'Abrir referencias do Espaco';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryActionLabel = _primaryActionLabel;

    return Card(
      key: const ValueKey('assistant-starter-response-card'),
      elevation: 0,
      color: const Color(0xFFF2F7F4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reply.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(reply.message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: reply.kind),
                _MetaChip(label: _formatEnumLabel(reply.intent.apiValue)),
                _MetaChip(label: _formatEnumLabel(reply.primaryActionKey)),
              ],
            ),
            if (primaryActionLabel != null &&
                onPrimaryActionRequested != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('assistant-starter-primary-action'),
                onPressed: () =>
                    onPrimaryActionRequested!(reply.primaryActionKey),
                icon: const Icon(Icons.arrow_forward),
                label: Text(primaryActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionComposer extends StatelessWidget {
  const _QuestionComposer({
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pergunte do seu jeito', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Se preferir, escreva uma pergunta livre. O app envia apenas sua pergunta e o mes de referencia; o restante do contexto vem do backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: const ValueKey('assistant-question-field'),
                    controller: controller,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => onSubmit(),
                    decoration: const InputDecoration(
                      labelText: 'O que voce quer entender?',
                      hintText:
                          'Ex.: Como posso economizar este mes sem mexer nas contas essenciais?',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe uma pergunta financeira.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('assistant-submit-button'),
                      onPressed: isLoading ? null : () => onSubmit(),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Perguntar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => onAction(),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationEntryCard extends StatelessWidget {
  const _ConversationEntryCard({required this.entry});

  final FinancialAssistantConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reply = entry.reply;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pergunta enviada',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF1C4B8E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(reply.question, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Mes de referencia: ${_formatMonthLabel(entry.referenceMonth)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B5B67),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Resposta do assistente', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(reply.answer, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: 'Modo ${reply.mode}'),
                _MetaChip(label: _formatEnumLabel(reply.intent)),
                if (reply.aiUsage != null)
                  _MetaChip(
                    label:
                        '${reply.aiUsage!.model} · ${reply.aiUsage!.totalTokens} tokens',
                  ),
              ],
            ),
            if (reply.hasSupportingData) ...[
              const SizedBox(height: 20),
              Text('Sinais de apoio', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PrimarySupportColumn(reply: reply),
                        const SizedBox(height: 12),
                        _SecondarySupportColumn(reply: reply),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _PrimarySupportColumn(reply: reply),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _SecondarySupportColumn(reply: reply),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimarySupportColumn extends StatelessWidget {
  const _PrimarySupportColumn({required this.reply});

  final FinancialAssistantReply reply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reply.summary != null) _SummarySupportCard(summary: reply.summary!),
        if (reply.summary != null) const SizedBox(height: 12),
        if (reply.topExpenses.isNotEmpty)
          _TopExpensesSupportCard(expenses: reply.topExpenses),
        if (reply.topExpenses.isNotEmpty) const SizedBox(height: 12),
        if (reply.recommendations.isNotEmpty)
          _RecommendationsSupportCard(recommendations: reply.recommendations),
      ],
    );
  }
}

class _SecondarySupportColumn extends StatelessWidget {
  const _SecondarySupportColumn({required this.reply});

  final FinancialAssistantReply reply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reply.monthComparison != null)
          _ComparisonSupportCard(comparison: reply.monthComparison!),
        if (reply.monthComparison != null) const SizedBox(height: 12),
        if (reply.highestSpendingCategory != null)
          _CategorySupportCard(category: reply.highestSpendingCategory!),
        if (reply.highestSpendingCategory != null) const SizedBox(height: 12),
        if (reply.increaseAlerts.isNotEmpty)
          _IncreaseAlertsSupportCard(alerts: reply.increaseAlerts),
        if (reply.increaseAlerts.isNotEmpty) const SizedBox(height: 12),
        if (reply.recurringExpenses.isNotEmpty)
          _RecurringSupportCard(expenses: reply.recurringExpenses),
      ],
    );
  }
}

class _SummarySupportCard extends StatelessWidget {
  const _SummarySupportCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Resumo do periodo',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _SupportMetric(
            label: 'Total',
            value: formatCurrency(summary.totalAmount),
          ),
          _SupportMetric(
            label: 'Pago',
            value: formatCurrency(summary.paidAmount),
          ),
          _SupportMetric(
            label: 'Pendente',
            value: formatCurrency(summary.remainingAmount),
          ),
          _SupportMetric(
            label: 'Lancamentos',
            value: '${summary.totalExpenses}',
          ),
        ],
      ),
    );
  }
}

class _ComparisonSupportCard extends StatelessWidget {
  const _ComparisonSupportCard({required this.comparison});

  final ReportMonthComparison comparison;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Comparacao mensal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${comparison.currentMonth} vs ${comparison.previousMonth}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Delta: ${formatCurrency(comparison.deltaAmount)} • ${comparison.deltaPercentage.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }
}

class _CategorySupportCard extends StatelessWidget {
  const _CategorySupportCard({required this.category});

  final ReportCategoryTotal category;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Categoria com maior peso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.categoryName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrency(category.totalAmount)} • ${category.sharePercentage.toStringAsFixed(2)}% do periodo',
          ),
        ],
      ),
    );
  }
}

class _TopExpensesSupportCard extends StatelessWidget {
  const _TopExpensesSupportCard({required this.expenses});

  final List<ReportTopExpense> expenses;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Maiores gastos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final expense in expenses.take(3)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(expense.description)),
                const SizedBox(width: 12),
                Text(formatCurrency(expense.amount)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RecommendationsSupportCard extends StatelessWidget {
  const _RecommendationsSupportCard({required this.recommendations});

  final List<ReportRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Recomendacoes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final recommendation in recommendations.take(3)) ...[
            Text(
              recommendation.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(recommendation.action),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _IncreaseAlertsSupportCard extends StatelessWidget {
  const _IncreaseAlertsSupportCard({required this.alerts});

  final List<ReportIncreaseAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Aumentos relevantes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final alert in alerts.take(3)) ...[
            Text(
              '${alert.categoryName} • + ${formatCurrency(alert.deltaAmount)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${alert.deltaPercentage.toStringAsFixed(2)}% vs mes anterior',
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RecurringSupportCard extends StatelessWidget {
  const _RecurringSupportCard({required this.expenses});

  final List<ReportRecurringExpense> expenses;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      title: 'Recorrencias detectadas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final expense in expenses.take(3)) ...[
            Text(
              expense.description,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${expense.occurrences} ocorrencias • media ${formatCurrency(expense.averageAmount)}',
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF6F8FA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF65727B)),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

String _formatMonthLabel(DateTime month) {
  const months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  return '${months[month.month - 1]}/${month.year}';
}

String _formatEnumLabel(String value) {
  return value
      .split('_')
      .map((part) {
        if (part.isEmpty) {
          return part;
        }
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}
