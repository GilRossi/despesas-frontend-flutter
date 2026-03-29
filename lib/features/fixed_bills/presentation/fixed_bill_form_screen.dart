import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/draft_review_panel.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_view_model.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _FixedBillFlowStep { collect, review, success }

class FixedBillFormScreen extends StatefulWidget {
  const FixedBillFormScreen({
    super.key,
    required this.fixedBillsRepository,
    required this.expensesRepository,
    required this.spaceReferencesRepository,
  });

  final FixedBillsRepository fixedBillsRepository;
  final ExpensesRepository expensesRepository;
  final SpaceReferencesRepository spaceReferencesRepository;

  @override
  State<FixedBillFormScreen> createState() => _FixedBillFormScreenState();
}

class _FixedBillFormScreenState extends State<FixedBillFormScreen> {
  static const _contexts = [
    'CASA',
    'VEICULO',
    'UBER',
    'PJ',
    'BUSCA_EMPREGO',
    'PETS',
    'GERAL',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _firstDueDateController = TextEditingController();

  late final FixedBillFormViewModel _viewModel;
  late DateTime _firstDueDate;

  _FixedBillFlowStep _step = _FixedBillFlowStep.collect;
  String? _selectedContext;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedSpaceReferenceId;
  FixedBillRecord? _createdFixedBill;

  CatalogOption? get _selectedCategory {
    if (_selectedCategoryId == null) {
      return null;
    }

    for (final option in _viewModel.catalogOptions) {
      if (option.id == _selectedCategoryId) {
        return option;
      }
    }

    return null;
  }

  List<ExpenseReference> get _subcategoryOptions =>
      _selectedCategory?.subcategories ?? const [];

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
    _viewModel = FixedBillFormViewModel(
      fixedBillsRepository: widget.fixedBillsRepository,
      expensesRepository: widget.expensesRepository,
      spaceReferencesRepository: widget.spaceReferencesRepository,
    );
    _firstDueDate = _normalizeDate(DateTime.now());
    _firstDueDateController.text = _formatDate(_firstDueDate);
    _viewModel.loadCatalogOptions();
    _viewModel.loadReferences();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _firstDueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickFirstDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDueDate,
      firstDate: DateTime(_firstDueDate.year - 1),
      lastDate: DateTime(_firstDueDate.year + 10),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _firstDueDate = _normalizeDate(picked);
      _firstDueDateController.text = _formatDate(_firstDueDate);
    });
  }

  void _continueToReview() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _buildInput() == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    _viewModel.clearSubmissionFeedback();
    setState(() => _step = _FixedBillFlowStep.review);
  }

  Future<void> _submit() async {
    final input = _buildInput();
    if (input == null) {
      setState(() => _step = _FixedBillFlowStep.collect);
      return;
    }

    FocusScope.of(context).unfocus();
    final created = await _viewModel.createFixedBill(input);

    if (!mounted) {
      return;
    }

    if (created == null) {
      if (_viewModel.hasFieldErrors) {
        setState(() => _step = _FixedBillFlowStep.collect);
      }
      return;
    }

    setState(() {
      _createdFixedBill = created;
      _step = _FixedBillFlowStep.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta fixa registrada com sucesso.')),
    );
  }

  void _resetDraft() {
    setState(() {
      _descriptionController.clear();
      _amountController.clear();
      _firstDueDate = _normalizeDate(DateTime.now());
      _firstDueDateController.text = _formatDate(_firstDueDate);
      _selectedContext = null;
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _selectedSpaceReferenceId = null;
      _createdFixedBill = null;
      _step = _FixedBillFlowStep.collect;
    });
    _viewModel.clearSubmissionFeedback();
  }

  CreateFixedBillInput? _buildInput() {
    final amount = _parseAmount(_amountController.text);
    if (amount == null ||
        amount <= 0 ||
        _selectedContext == null ||
        _selectedCategoryId == null ||
        _selectedSubcategoryId == null) {
      return null;
    }

    return CreateFixedBillInput(
      description: _descriptionController.text.trim(),
      amount: amount,
      firstDueDate: _firstDueDate,
      frequency: FixedBillFrequency.monthly,
      context: _selectedContext!,
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId!,
      spaceReferenceId: _selectedSpaceReferenceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: const RouteBackButton(fallbackRoute: '/assistant'),
        title: const Text('Cadastrar minhas contas fixas'),
      ),
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
                  if (_step == _FixedBillFlowStep.collect) _buildCollectStep(),
                  if (_step == _FixedBillFlowStep.review) _buildReviewStep(),
                  if (_step == _FixedBillFlowStep.success) _buildSuccessStep(),
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

    if (_viewModel.isLoadingCatalog && !_viewModel.hasCatalogOptions) {
      return const _StateCard(
        key: ValueKey('fixed-bill-loading-catalog-card'),
        title: 'Preparando o fluxo de conta fixa',
        message:
            'Carregando o catalogo que o backend usa como fonte de verdade.',
        showProgress: true,
      );
    }

    if (_viewModel.loadCatalogErrorMessage != null &&
        !_viewModel.hasCatalogOptions) {
      return _StateCard(
        key: const ValueKey('fixed-bill-catalog-error-card'),
        title: 'Nao foi possivel carregar o catalogo',
        message: _viewModel.loadCatalogErrorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: _viewModel.loadCatalogOptions,
      );
    }

    if (!_viewModel.hasCatalogOptions) {
      return const _StateCard(
        key: ValueKey('fixed-bill-empty-catalog-card'),
        title: 'Catalogo indisponivel',
        message:
            'Cadastre ao menos uma categoria e subcategoria ativas antes de registrar uma conta fixa.',
      );
    }

    return SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SummaryHeader(
              title: 'Conte o essencial da conta fixa',
              subtitle:
                  'Neste fluxo base voce define nome, valor, primeiro vencimento e o encaixe no catalogo real antes da revisao final.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('fixed-bill-form-description-field'),
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              maxLength: 140,
              decoration: InputDecoration(
                labelText: 'Como voce quer identificar essa conta fixa?',
                hintText: 'Ex.: Internet fibra, Aluguel, Plano de saude',
                errorText: _viewModel.fieldError('description'),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Informe uma descricao para a conta fixa.';
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
              key: const ValueKey('fixed-bill-form-amount-field'),
              controller: _amountController,
              textInputAction: TextInputAction.next,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Qual o valor mensal?',
                hintText: 'Ex.: 129,90',
                errorText: _viewModel.fieldError('amount'),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Informe o valor da conta fixa.';
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
              key: const ValueKey('fixed-bill-form-first-due-date-field'),
              controller: _firstDueDateController,
              readOnly: true,
              onTap: _pickFirstDueDate,
              decoration: InputDecoration(
                labelText: 'Quando vence pela primeira vez?',
                errorText: _viewModel.fieldError('firstDueDate'),
                suffixIcon: IconButton(
                  tooltip: 'Selecionar data',
                  onPressed: _pickFirstDueDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o primeiro vencimento.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Recorrencia base deste release',
              ),
              child: const Text('Mensal'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey(
                'fixed-bill-form-context-field-${_selectedContext ?? 'none'}',
              ),
              initialValue: _selectedContext,
              decoration: InputDecoration(
                labelText: 'Onde essa conta fixa se encaixa?',
                errorText: _viewModel.fieldError('context'),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Escolha o contexto'),
                ),
                for (final contextValue in _contexts)
                  DropdownMenuItem<String?>(
                    value: contextValue,
                    child: Text(_formatContextLabel(contextValue)),
                  ),
              ],
              onChanged: (value) {
                setState(() => _selectedContext = value);
                _viewModel.clearFieldError('context');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione o contexto da conta fixa.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey(
                'fixed-bill-form-category-field-${_selectedCategoryId ?? 'none'}',
              ),
              initialValue: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Categoria',
                errorText: _viewModel.fieldError('categoryId'),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Escolha a categoria'),
                ),
                for (final option in _viewModel.catalogOptions)
                  DropdownMenuItem<int?>(
                    value: option.id,
                    child: Text(option.name),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _selectedSubcategoryId = null;
                });
                _viewModel.clearFieldError('categoryId');
                _viewModel.clearFieldError('subcategoryId');
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione a categoria.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey(
                'fixed-bill-form-subcategory-field-${_selectedSubcategoryId ?? 'none'}',
              ),
              initialValue: _selectedSubcategoryId,
              decoration: InputDecoration(
                labelText: 'Subcategoria',
                helperText:
                    _selectedCategoryId != null && _subcategoryOptions.isEmpty
                    ? 'A categoria selecionada nao possui subcategorias ativas.'
                    : null,
                errorText: _viewModel.fieldError('subcategoryId'),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Escolha a subcategoria'),
                ),
                for (final option in _subcategoryOptions)
                  DropdownMenuItem<int?>(
                    value: option.id,
                    child: Text(option.name),
                  ),
              ],
              onChanged: (value) {
                setState(() => _selectedSubcategoryId = value);
                _viewModel.clearFieldError('subcategoryId');
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione a subcategoria.';
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
            _ActionBar(
              secondary: OutlinedButton(
                onPressed: _viewModel.isSubmitting
                    ? null
                    : () => context.go('/assistant'),
                child: const Text('Voltar ao assistente'),
              ),
              primary: FilledButton.icon(
                key: const ValueKey('fixed-bill-form-continue-button'),
                onPressed: _viewModel.isSubmitting ? null : _continueToReview,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar para revisao'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final amount = _parseAmount(_amountController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DraftReviewPanel(
          key: const ValueKey('fixed-bill-review-panel'),
          title: 'Revise antes de confirmar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O backend continua como fonte de verdade. Aqui voce so revisa o cadastro base antes do POST real.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 16),
              _ReviewRow(
                label: 'Descricao',
                value: _descriptionController.text.trim(),
              ),
              _ReviewRow(label: 'Valor mensal', value: formatCurrency(amount)),
              _ReviewRow(
                label: 'Primeiro vencimento',
                value: _formatDate(_firstDueDate),
              ),
              _ReviewRow(
                label: 'Recorrencia',
                value: FixedBillFrequency.monthly.label,
              ),
              _ReviewRow(
                label: 'Contexto',
                value: _selectedContext == null
                    ? '-'
                    : _formatContextLabel(_selectedContext!),
              ),
              _ReviewRow(
                label: 'Categoria',
                value: _selectedCategory?.name ?? '-',
              ),
              _ReviewRow(
                label: 'Subcategoria',
                value: _selectedSubcategoryName ?? '-',
              ),
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
        _ActionBar(
          secondary: OutlinedButton(
            onPressed: _viewModel.isSubmitting
                ? null
                : () => setState(() => _step = _FixedBillFlowStep.collect),
            child: const Text('Voltar e ajustar'),
          ),
          primary: FilledButton.icon(
            key: const ValueKey('fixed-bill-review-confirm-button'),
            onPressed: _viewModel.isSubmitting ? null : _submit,
            icon: _viewModel.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _viewModel.isSubmitting
                  ? 'Confirmando...'
                  : 'Confirmar conta fixa',
            ),
          ),
        ),
      ],
    );
  }

  String? get _selectedSubcategoryName {
    final selectedSubcategoryId = _selectedSubcategoryId;
    if (selectedSubcategoryId == null) {
      return null;
    }

    for (final option in _subcategoryOptions) {
      if (option.id == selectedSubcategoryId) {
        return option.name;
      }
    }

    return null;
  }

  Widget _buildSuccessStep() {
    final createdFixedBill = _createdFixedBill;
    if (createdFixedBill == null) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      key: const ValueKey('fixed-bill-success-card'),
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
                  title: 'Conta fixa registrada',
                  subtitle:
                      'O cadastro base foi salvo no household atual e ficou pronto para os proximos passos do app consumirem.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Descricao', value: createdFixedBill.description),
          _ReviewRow(
            label: 'Valor mensal',
            value: formatCurrency(createdFixedBill.amount),
          ),
          _ReviewRow(
            label: 'Primeiro vencimento',
            value: _formatDate(createdFixedBill.firstDueDate),
          ),
          _ReviewRow(
            label: 'Recorrencia',
            value: createdFixedBill.frequency.label,
          ),
          _ReviewRow(
            label: 'Contexto',
            value: _formatContextLabel(createdFixedBill.context),
          ),
          _ReviewRow(label: 'Categoria', value: createdFixedBill.category.name),
          _ReviewRow(
            label: 'Subcategoria',
            value: createdFixedBill.subcategory.name,
          ),
          _ReviewRow(
            label: 'Referencia do Espaco',
            value:
                createdFixedBill.spaceReference?.name ??
                'Sem referencia vinculada',
          ),
          _ReviewRow(
            label: 'Registrado em',
            value: _formatDateTime(createdFixedBill.createdAt),
          ),
          const SizedBox(height: 20),
          _ActionBar(
            secondary: OutlinedButton(
              onPressed: () => context.go('/assistant'),
              child: const Text('Voltar ao assistente'),
            ),
            primary: FilledButton.icon(
              key: const ValueKey('fixed-bill-success-create-another-button'),
              onPressed: _resetDraft,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar outra conta fixa'),
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
    return '${_formatDate(normalized)} as $hour:$minute';
  }

  static double? _parseAmount(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String _formatContextLabel(String value) {
    return switch (value) {
      'CASA' => 'Casa',
      'VEICULO' => 'Veiculo',
      'UBER' => 'Uber',
      'PJ' => 'PJ',
      'BUSCA_EMPREGO' => 'Busca de emprego',
      'PETS' => 'Pets',
      'GERAL' => 'Geral',
      _ => value,
    };
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.step});

  final _FixedBillFlowStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SummaryHeader(
            title: 'Cadastrar minhas contas fixas',
            subtitle:
                'Um fluxo curto para registrar a base de uma conta recorrente sem te jogar num CRUD frio.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StepChip(
                label: '1. Coleta guiada',
                isActive: step == _FixedBillFlowStep.collect,
              ),
              _StepChip(
                label: '2. Revisao',
                isActive: step == _FixedBillFlowStep.review,
              ),
              _StepChip(
                label: '3. Confirmacao',
                isActive: step == _FixedBillFlowStep.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step == _FixedBillFlowStep.collect
                ? 'Voce preenche so o essencial: descricao, valor, primeiro vencimento, contexto, catalogo e uma referencia opcional do seu Espaco.'
                : step == _FixedBillFlowStep.review
                ? 'Agora confira com calma. A gravacao real so acontece depois da sua confirmacao.'
                : 'Tudo certo. O backend confirmou o cadastro da conta fixa.',
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
          'Se essa conta fixa estiver ligada a cliente, projeto ou outra referencia do seu Espaco, voce pode conectar agora. Se nao fizer sentido, siga sem isso.',
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
              'fixed-bill-form-space-reference-field-${selectedReferenceId ?? 'none'}',
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

class _StateCard extends StatelessWidget {
  const _StateCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryHeader(title: title, subtitle: message),
          if (showProgress) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[primary];
    if (secondary != null) {
      children.insert(0, secondary!);
    }

    return Wrap(
      alignment: WrapAlignment.end,
      runAlignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: children,
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
