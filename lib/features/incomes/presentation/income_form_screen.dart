import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/draft_review_panel.dart';
import 'package:despesas_frontend/core/ui/components/primary_action_bar.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/domain/income_record.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';
import 'package:despesas_frontend/features/incomes/presentation/income_form_view_model.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _IncomeFlowStep { collect, review, success }

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({
    super.key,
    required this.incomesRepository,
    required this.spaceReferencesRepository,
  });

  final IncomesRepository incomesRepository;
  final SpaceReferencesRepository spaceReferencesRepository;

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receivedOnController = TextEditingController();

  late final IncomeFormViewModel _viewModel;
  late DateTime _receivedOn;

  _IncomeFlowStep _step = _IncomeFlowStep.collect;
  int? _selectedSpaceReferenceId;
  IncomeRecord? _createdIncome;

  SpaceReferenceItem? get _selectedReference {
    if (_selectedSpaceReferenceId == null) {
      return null;
    }

    for (final reference in _viewModel.references) {
      if (reference.id == _selectedSpaceReferenceId) {
        return reference;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = IncomeFormViewModel(
      incomesRepository: widget.incomesRepository,
      spaceReferencesRepository: widget.spaceReferencesRepository,
    )..loadReferences();
    _receivedOn = _normalizeDate(DateTime.now());
    _receivedOnController.text = _formatDate(_receivedOn);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _receivedOnController.dispose();
    super.dispose();
  }

  Future<void> _pickReceivedOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(_receivedOn.year - 5),
      lastDate: DateTime(_receivedOn.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _receivedOn = _normalizeDate(picked);
      _receivedOnController.text = _formatDate(_receivedOn);
    });
  }

  void _continueToReview() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _buildInput() == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    _viewModel.clearSubmissionFeedback();
    setState(() => _step = _IncomeFlowStep.review);
  }

  Future<void> _submit() async {
    final input = _buildInput();
    if (input == null) {
      setState(() => _step = _IncomeFlowStep.collect);
      return;
    }

    FocusScope.of(context).unfocus();
    final created = await _viewModel.createIncome(input);

    if (!mounted) {
      return;
    }

    if (created == null) {
      if (_viewModel.hasFieldErrors) {
        setState(() => _step = _IncomeFlowStep.collect);
      }
      return;
    }

    setState(() {
      _createdIncome = created;
      _step = _IncomeFlowStep.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ganho registrado com sucesso.')),
    );
  }

  void _resetDraft() {
    setState(() {
      _descriptionController.clear();
      _amountController.clear();
      _receivedOn = _normalizeDate(DateTime.now());
      _receivedOnController.text = _formatDate(_receivedOn);
      _selectedSpaceReferenceId = null;
      _createdIncome = null;
      _step = _IncomeFlowStep.collect;
    });
    _viewModel.clearSubmissionFeedback();
  }

  CreateIncomeInput? _buildInput() {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      return null;
    }

    return CreateIncomeInput(
      description: _descriptionController.text.trim(),
      amount: amount,
      receivedOn: _receivedOn,
      spaceReferenceId: _selectedSpaceReferenceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar meus ganhos')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return ResponsiveScrollBody(
              maxWidth: 860,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + keyboardBottomInset,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(step: _step),
                  const SizedBox(height: 16),
                  if (_step == _IncomeFlowStep.collect) _buildCollectStep(),
                  if (_step == _IncomeFlowStep.review) _buildReviewStep(),
                  if (_step == _IncomeFlowStep.success) _buildSuccessStep(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollectStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SummaryHeader(
                  title: 'Conte de um jeito simples',
                  subtitle:
                      'Vamos registrar o que entrou, quando caiu e, se fizer sentido, ligar esse ganho a uma referencia do seu Espaco.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('income-form-description-field'),
                  controller: _descriptionController,
                  textInputAction: TextInputAction.next,
                  maxLength: 140,
                  decoration: InputDecoration(
                    labelText: 'Como voce quer identificar esse ganho?',
                    hintText: 'Ex.: Salario principal, Freelance de marco',
                    errorText: _viewModel.fieldError('description'),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Informe uma descricao para o ganho.';
                    }
                    if (trimmed.length > 140) {
                      return 'Use no maximo 140 caracteres.';
                    }
                    return null;
                  },
                  onChanged: (_) => _viewModel.clearFieldError('description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('income-form-amount-field'),
                  controller: _amountController,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quanto entrou?',
                    hintText: 'Ex.: 1800,00',
                    errorText: _viewModel.fieldError('amount'),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Informe o valor do ganho.';
                    }
                    final amount = _parseAmount(trimmed);
                    if (amount == null || amount <= 0) {
                      return 'Informe um valor maior que zero.';
                    }
                    return null;
                  },
                  onChanged: (_) => _viewModel.clearFieldError('amount'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('income-form-received-on-field'),
                  controller: _receivedOnController,
                  readOnly: true,
                  onTap: _pickReceivedOn,
                  decoration: InputDecoration(
                    labelText: 'Quando esse valor caiu?',
                    errorText: _viewModel.fieldError('receivedOn'),
                    suffixIcon: IconButton(
                      tooltip: 'Selecionar data',
                      onPressed: _pickReceivedOn,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a data em que o ganho entrou.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _ReferenceFieldSection(
                  isLoading: _viewModel.isLoadingReferences,
                  loadErrorMessage: _viewModel.loadReferencesErrorMessage,
                  references: _viewModel.references,
                  selectedReferenceId: _selectedSpaceReferenceId,
                  fieldError: _viewModel.fieldError('spaceReferenceId'),
                  onRetry: _viewModel.loadReferences,
                  onChanged: (value) {
                    setState(() => _selectedSpaceReferenceId = value);
                    _viewModel.clearFieldError('spaceReferenceId');
                  },
                ),
                if (_viewModel.submitErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.submitErrorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryActionBar(
                  secondary: OutlinedButton(
                    onPressed: _viewModel.isSubmitting
                        ? null
                        : () => context.go('/assistant'),
                    child: const Text('Voltar ao assistente'),
                  ),
                  primary: FilledButton.icon(
                    key: const ValueKey('income-form-continue-button'),
                    onPressed: _viewModel.isSubmitting
                        ? null
                        : _continueToReview,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar para revisao'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final amount = _parseAmount(_amountController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DraftReviewPanel(
          key: const ValueKey('income-review-panel'),
          title: 'Revise antes de confirmar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backend continua como fonte de verdade. Aqui voce so confere se esta tudo certo antes de gravar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 16),
              _ReviewRow(
                label: 'Descricao',
                value: _descriptionController.text.trim(),
              ),
              _ReviewRow(label: 'Valor', value: formatCurrency(amount)),
              _ReviewRow(label: 'Recebido em', value: _formatDate(_receivedOn)),
              _ReviewRow(
                label: 'Referencia do Espaco',
                value:
                    _selectedReference?.name ?? 'Sem referencia por enquanto',
              ),
            ],
          ),
        ),
        if (_viewModel.submitErrorMessage != null &&
            !_viewModel.hasFieldErrors) ...[
          const SizedBox(height: 16),
          Text(
            _viewModel.submitErrorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryActionBar(
          secondary: OutlinedButton(
            onPressed: _viewModel.isSubmitting
                ? null
                : () => setState(() => _step = _IncomeFlowStep.collect),
            child: const Text('Voltar e ajustar'),
          ),
          primary: FilledButton.icon(
            key: const ValueKey('income-review-confirm-button'),
            onPressed: _viewModel.isSubmitting ? null : _submit,
            icon: _viewModel.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _viewModel.isSubmitting ? 'Confirmando...' : 'Confirmar ganho',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final createdIncome = _createdIncome;
    if (createdIncome == null) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      key: const ValueKey('income-success-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F6EC),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: SummaryHeader(
                  title: 'Ganho registrado',
                  subtitle:
                      'Seu ganho ja foi salvo no household atual e ficou pronto para o restante do app consumir.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Descricao', value: createdIncome.description),
          _ReviewRow(
            label: 'Valor',
            value: formatCurrency(createdIncome.amount),
          ),
          _ReviewRow(
            label: 'Recebido em',
            value: _formatDate(createdIncome.receivedOn),
          ),
          _ReviewRow(
            label: 'Referencia do Espaco',
            value:
                createdIncome.spaceReference?.name ??
                'Sem referencia vinculada',
          ),
          _ReviewRow(
            label: 'Registrado em',
            value: _formatDateTime(createdIncome.createdAt),
          ),
          const SizedBox(height: 20),
          PrimaryActionBar(
            secondary: OutlinedButton(
              onPressed: () => context.go('/assistant'),
              child: const Text('Voltar ao assistente'),
            ),
            primary: FilledButton.icon(
              key: const ValueKey('income-success-create-another-button'),
              onPressed: _resetDraft,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar outro ganho'),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _formatDateTime(DateTime value) {
    final normalized = value.toLocal();
    final hour = normalized.hour.toString().padLeft(2, '0');
    final minute = normalized.minute.toString().padLeft(2, '0');
    return '${_formatDate(normalized)} às $hour:$minute';
  }

  static double? _parseAmount(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.step});

  final _IncomeFlowStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SummaryHeader(
            title: 'Cadastrar meus ganhos',
            subtitle:
                'Um fluxo curto para registrar entradas reais sem te prender em um formulario frio.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StepChip(
                label: '1. Coleta guiada',
                isActive: step == _IncomeFlowStep.collect,
              ),
              _StepChip(
                label: '2. Revisao',
                isActive: step == _IncomeFlowStep.review,
              ),
              _StepChip(
                label: '3. Confirmacao',
                isActive: step == _IncomeFlowStep.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step == _IncomeFlowStep.collect
                ? 'Preencha so o essencial: descricao, valor, data e, se fizer sentido, uma referencia opcional do seu Espaco.'
                : step == _IncomeFlowStep.review
                ? 'Agora confira tudo com calma. A gravacao real so acontece depois da sua confirmacao.'
                : 'Tudo certo. O backend confirmou o cadastro do ganho.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceFieldSection extends StatelessWidget {
  const _ReferenceFieldSection({
    required this.isLoading,
    required this.loadErrorMessage,
    required this.references,
    required this.selectedReferenceId,
    required this.fieldError,
    required this.onRetry,
    required this.onChanged,
  });

  final bool isLoading;
  final String? loadErrorMessage;
  final List<SpaceReferenceItem> references;
  final int? selectedReferenceId;
  final String? fieldError;
  final Future<void> Function() onRetry;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Referencia opcional', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Se esse ganho estiver ligado a cliente, projeto ou outra referencia do seu Espaco, voce pode conectar agora. Se nao fizer sentido, siga sem isso.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Carregando referencias do seu Espaco...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
        ] else if (loadErrorMessage != null) ...[
          Text(
            loadErrorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar carregar novamente'),
          ),
        ] else if (references.isEmpty) ...[
          Text(
            'Ainda nao ha referencias cadastradas no seu Espaco. Voce pode seguir sem vincular nenhuma agora.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
        ] else ...[
          DropdownButtonFormField<int?>(
            key: ValueKey(
              'income-form-space-reference-field-${selectedReferenceId ?? 'none'}',
            ),
            initialValue: selectedReferenceId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Referencia do Espaco',
              errorText: fieldError,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sem referencia por enquanto'),
              ),
              for (final reference in references)
                DropdownMenuItem<int?>(
                  value: reference.id,
                  child: Text(reference.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F2FF) : const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : const Color(0xFF65727B),
          ),
        ),
      ),
    );
  }
}
