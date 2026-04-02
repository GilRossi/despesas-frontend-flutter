import 'package:despesas_frontend/core/network/api_exception.dart';
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
    this.fixedBillId,
  });

  final FixedBillsRepository fixedBillsRepository;
  final ExpensesRepository expensesRepository;
  final SpaceReferencesRepository spaceReferencesRepository;
  final int? fixedBillId;

  @override
  State<FixedBillFormScreen> createState() => _FixedBillFormScreenState();
}

class _FixedBillFormScreenState extends State<FixedBillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _firstDueDateController = TextEditingController();

  late final FixedBillFormViewModel _viewModel;
  late DateTime _firstDueDate;

  _FixedBillFlowStep _step = _FixedBillFlowStep.collect;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedSpaceReferenceId;
  FixedBillFrequency _selectedFrequency = FixedBillFrequency.monthly;
  FixedBillRecord? _createdFixedBill;
  bool _isLoadingInitialRecord = false;
  String? _loadInitialRecordMessage;

  bool get _isEditMode => widget.fixedBillId != null;

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
    if (_isEditMode) {
      _loadInitialRecord();
    }
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

  Future<void> _loadInitialRecord() async {
    final fixedBillId = widget.fixedBillId;
    if (fixedBillId == null) {
      return;
    }

    setState(() {
      _isLoadingInitialRecord = true;
      _loadInitialRecordMessage = null;
    });

    try {
      final record = await widget.fixedBillsRepository.getFixedBill(
        fixedBillId,
      );
      if (!mounted) {
        return;
      }
      _applyInitialRecord(record);
      setState(() {
        _createdFixedBill = record;
        _isLoadingInitialRecord = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadInitialRecordMessage = error.message;
        _isLoadingInitialRecord = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadInitialRecordMessage =
            'Não foi possível carregar esta conta fixa agora.';
        _isLoadingInitialRecord = false;
      });
    }
  }

  void _applyInitialRecord(FixedBillRecord record) {
    _descriptionController.text = record.description;
    _amountController.text = record.amount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _firstDueDate = _normalizeDate(record.firstDueDate);
    _firstDueDateController.text = _formatDate(_firstDueDate);
    _selectedCategoryId = record.category.id;
    _selectedSubcategoryId = record.subcategory.id;
    _selectedSpaceReferenceId = record.spaceReference?.id;
    _selectedFrequency = record.frequency;
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
    final created = await _viewModel.submitFixedBill(
      fixedBillId: widget.fixedBillId,
      input: input,
    );

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
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Conta fixa atualizada com sucesso.'
              : 'Conta fixa cadastrada com sucesso.',
        ),
      ),
    );
  }

  void _resetDraft() {
    if (_isEditMode && _createdFixedBill != null) {
      setState(() {
        _step = _FixedBillFlowStep.collect;
      });
      return;
    }
    setState(() {
      _descriptionController.clear();
      _amountController.clear();
      _firstDueDate = _normalizeDate(DateTime.now());
      _firstDueDateController.text = _formatDate(_firstDueDate);
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _selectedSpaceReferenceId = null;
      _selectedFrequency = FixedBillFrequency.monthly;
      _createdFixedBill = null;
      _step = _FixedBillFlowStep.collect;
    });
    _viewModel.clearSubmissionFeedback();
  }

  CreateFixedBillInput? _buildInput() {
    final amount = _parseAmount(_amountController.text);
    if (amount == null ||
        amount <= 0 ||
        _selectedCategoryId == null ||
        _selectedSubcategoryId == null) {
      return null;
    }

    return CreateFixedBillInput(
      description: _descriptionController.text.trim(),
      amount: amount,
      firstDueDate: _firstDueDate,
      frequency: _selectedFrequency,
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
        leading: const RouteBackButton(fallbackRoute: '/fixed-bills'),
        title: Text(_isEditMode ? 'Editar conta fixa' : 'Cadastrar conta fixa'),
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
                  _HeroCard(step: _step, isEditMode: _isEditMode),
                  const SizedBox(height: 16),
                  if (_isLoadingInitialRecord)
                    const _StateCard(
                      key: ValueKey('fixed-bill-loading-draft-card'),
                      title: 'Carregando esta conta fixa',
                      message:
                          'Buscando a regra atual para você editar sem perder o contexto.',
                      showProgress: true,
                    ),
                  if (!_isLoadingInitialRecord &&
                      _loadInitialRecordMessage != null)
                    _StateCard(
                      key: const ValueKey('fixed-bill-load-draft-error-card'),
                      title: 'Não foi possível abrir esta conta fixa',
                      message: _loadInitialRecordMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _loadInitialRecord,
                    ),
                  if (!_isLoadingInitialRecord &&
                      _loadInitialRecordMessage == null) ...[
                    if (_step == _FixedBillFlowStep.collect)
                      _buildCollectStep(),
                    if (_step == _FixedBillFlowStep.review) _buildReviewStep(),
                    if (_step == _FixedBillFlowStep.success)
                      _buildSuccessStep(),
                  ],
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
            'Carregando as categorias usadas para organizar suas contas fixas.',
        showProgress: true,
      );
    }

    if (_viewModel.loadCatalogErrorMessage != null &&
        !_viewModel.hasCatalogOptions) {
      return _StateCard(
        key: const ValueKey('fixed-bill-catalog-error-card'),
        title: 'Não foi possível carregar o catálogo',
        message: _viewModel.loadCatalogErrorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: _viewModel.loadCatalogOptions,
      );
    }

    if (!_viewModel.hasCatalogOptions) {
      return const _StateCard(
        key: ValueKey('fixed-bill-empty-catalog-card'),
        title: 'Catálogo indisponível',
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
                  'Defina ou ajuste a regra recorrente. Esta tela cuida da regra; o lançamento do dia a dia continua em Minhas contas fixas, no botão Lançar despesa.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('fixed-bill-form-description-field'),
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              maxLength: 140,
              decoration: InputDecoration(
                labelText: 'Como você quer identificar essa conta fixa?',
                hintText: 'Ex.: Internet fibra, Aluguel, Plano de saude',
                errorText: _viewModel.fieldError('description'),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Informe uma descrição para a conta fixa.';
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
                labelText: _selectedFrequency == FixedBillFrequency.weekly
                    ? 'Qual o valor semanal?'
                    : 'Qual o valor mensal?',
                hintText: _selectedFrequency == FixedBillFrequency.weekly
                    ? 'Ex.: 90,00'
                    : 'Ex.: 129,90',
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
                labelText: 'Periodicidade previsível',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<FixedBillFrequency>(
                    key: const ValueKey('fixed-bill-form-frequency-field'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: FixedBillFrequency.weekly,
                        label: Text('Semanal'),
                        icon: Icon(Icons.calendar_view_week_outlined),
                      ),
                      ButtonSegment(
                        value: FixedBillFrequency.monthly,
                        label: Text('Mensal'),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                    selected: {_selectedFrequency},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) {
                        return;
                      }
                      setState(() => _selectedFrequency = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFrequency == FixedBillFrequency.weekly
                        ? 'Use semanal para contas previsíveis que se repetem toda semana.'
                        : 'Use mensal para contas previsíveis que se repetem todo mês.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF65727B),
                    ),
                  ),
                ],
              ),
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
                    ? 'A categoria selecionada não possui subcategorias ativas.'
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
                key: const ValueKey('fixed-bill-form-open-list-button'),
                onPressed: _viewModel.isSubmitting
                    ? null
                    : () => context.go('/fixed-bills'),
                child: const Text('Ver minhas contas'),
              ),
              primary: FilledButton.icon(
                key: const ValueKey('fixed-bill-form-continue-button'),
                onPressed: _viewModel.isSubmitting ? null : _continueToReview,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar para revisão'),
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
                'Confira os dados antes de salvar a regra recorrente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 16),
              _ReviewRow(
                label: 'Descrição',
                value: _descriptionController.text.trim(),
              ),
              _ReviewRow(
                label: _selectedFrequency == FixedBillFrequency.weekly
                    ? 'Valor semanal'
                    : 'Valor mensal',
                value: formatCurrency(amount),
              ),
              _ReviewRow(
                label: 'Primeiro vencimento',
                value: _formatDate(_firstDueDate),
              ),
              _ReviewRow(label: 'Recorrência', value: _selectedFrequency.label),
              _ReviewRow(
                label: 'Categoria',
                value: _selectedCategory?.name ?? '-',
              ),
              _ReviewRow(
                label: 'Subcategoria',
                value: _selectedSubcategoryName ?? '-',
              ),
              _ReviewRow(
                label: 'Referência do espaço',
                value:
                    _selectedReference?.name ?? 'Sem referência por enquanto',
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
              Expanded(
                child: SummaryHeader(
                  title: _isEditMode
                      ? 'Conta fixa atualizada'
                      : 'Conta fixa registrada',
                  subtitle: _isEditMode
                      ? 'As próximas despesas lançadas a partir desta regra vão usar os dados novos. As despesas já geradas continuam preservadas em Despesas.'
                      : 'A regra recorrente foi salva. Quando chegar o vencimento, abra Minhas contas fixas e use Lançar despesa para criar a despesa real em Despesas.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Descrição', value: createdFixedBill.description),
          _ReviewRow(
            label: createdFixedBill.frequency == FixedBillFrequency.weekly
                ? 'Valor semanal'
                : 'Valor mensal',
            value: formatCurrency(createdFixedBill.amount),
          ),
          _ReviewRow(
            label: 'Primeiro vencimento',
            value: _formatDate(createdFixedBill.firstDueDate),
          ),
          _ReviewRow(
            label: 'Recorrência',
            value: createdFixedBill.frequency.label,
          ),
          _ReviewRow(label: 'Categoria', value: createdFixedBill.category.name),
          _ReviewRow(
            label: 'Subcategoria',
            value: createdFixedBill.subcategory.name,
          ),
          _ReviewRow(
            label: 'Referência do espaço',
            value:
                createdFixedBill.spaceReference?.name ??
                'Sem referência vinculada',
          ),
          _ReviewRow(
            label: 'Registrado em',
            value: _formatDateTime(createdFixedBill.createdAt),
          ),
          const SizedBox(height: 20),
          _ActionBar(
            secondary: OutlinedButton(
              key: const ValueKey('fixed-bill-success-open-list-button'),
              onPressed: () => context.go('/fixed-bills'),
              child: Text(
                _isEditMode ? 'Voltar para minhas contas' : 'Ver minhas contas',
              ),
            ),
            primary: FilledButton.icon(
              key: const ValueKey('fixed-bill-success-create-another-button'),
              onPressed: _resetDraft,
              icon: Icon(_isEditMode ? Icons.edit_outlined : Icons.add),
              label: Text(
                _isEditMode
                    ? 'Continuar editando'
                    : 'Cadastrar outra conta fixa',
              ),
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
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.step, required this.isEditMode});

  final _FixedBillFlowStep step;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SummaryHeader(
            title: 'Ciclo da conta fixa',
            subtitle:
                'Conta fixa é a sua regra recorrente. A despesa real entra em Despesas quando você usa Lançar despesa em Minhas contas fixas.',
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
                label: '2. Revisão',
                isActive: step == _FixedBillFlowStep.review,
              ),
              _StepChip(
                label: '3. Confirmação',
                isActive: step == _FixedBillFlowStep.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step == _FixedBillFlowStep.collect
                ? isEditMode
                      ? 'Aqui você ajusta a regra recorrente. O que mudar passa a valer para os próximos lançamentos, sem reescrever despesas já geradas.'
                      : 'Aqui você registra a regra recorrente: descrição, valor, primeiro vencimento, periodicidade semanal ou mensal, categorias e referência opcional.'
                : step == _FixedBillFlowStep.review
                ? 'Agora confira com calma. O salvamento só acontece depois da sua confirmação.'
                : isEditMode
                ? 'Tudo certo. A regra recorrente foi atualizada.'
                : 'Tudo certo. A regra recorrente foi criada e já pode lançar despesas reais depois.',
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
        Text('Referência opcional', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Se essa conta fixa estiver ligada a cliente, projeto ou outra referência do seu espaço, você pode conectar agora. Se não fizer sentido, siga sem isso.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Carregando referências do seu espaço...',
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
            'Ainda não há referências cadastradas no seu espaço. Você pode seguir sem vincular nenhuma agora.',
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
              labelText: 'Referência do espaço',
              errorText: fieldError,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sem referência por enquanto'),
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
