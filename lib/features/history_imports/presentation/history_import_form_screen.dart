import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:despesas_frontend/core/ui/components/draft_review_panel.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_record.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';
import 'package:despesas_frontend/features/history_imports/presentation/history_import_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

enum _HistoryImportFlowStep { collect, review, success }

class HistoryImportFormScreen extends StatefulWidget {
  const HistoryImportFormScreen({
    super.key,
    required this.historyImportsRepository,
    required this.expensesRepository,
    required this.sessionController,
  });

  final HistoryImportsRepository historyImportsRepository;
  final ExpensesRepository expensesRepository;
  final SessionController sessionController;

  @override
  State<HistoryImportFormScreen> createState() =>
      _HistoryImportFormScreenState();
}

class _HistoryImportFormScreenState extends State<HistoryImportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_HistoryImportEntryDraft> _entries = [];

  late final HistoryImportFormViewModel _viewModel;

  int _entrySequence = 0;
  _HistoryImportFlowStep _step = _HistoryImportFlowStep.collect;
  HistoryImportPaymentMethod? _selectedPaymentMethod;
  HistoryImportResult? _createdImport;

  @override
  void initState() {
    super.initState();
    _viewModel = HistoryImportFormViewModel(
      historyImportsRepository: widget.historyImportsRepository,
      expensesRepository: widget.expensesRepository,
    );
    _entries.add(_newEntryDraft());
    _viewModel.loadCatalogOptions();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  _HistoryImportEntryDraft _newEntryDraft() {
    _entrySequence += 1;
    return _HistoryImportEntryDraft(
      id: _entrySequence,
      initialDate: _normalizeDate(DateTime.now()),
    );
  }

  Future<void> _pickEntryDate(_HistoryImportEntryDraft entry, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: DateTime(DateTime.now().year - 15),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() => entry.setDate(_normalizeDate(picked)));
    _clearEntryFieldError(index, 'date');
  }

  void _addEntry() {
    setState(() => _entries.add(_newEntryDraft()));
    _viewModel.clearSubmissionFeedback();
  }

  void _duplicateLastEntry() {
    if (_entries.isEmpty) {
      return;
    }

    final source = _entries.last;
    final duplicated = _newEntryDraft();
    duplicated.descriptionController.text = source.descriptionController.text;
    duplicated.amountController.text = source.amountController.text;
    duplicated.notesController.text = source.notesController.text;
    duplicated.selectedCategoryId = source.selectedCategoryId;
    duplicated.selectedSubcategoryId = source.selectedSubcategoryId;
    duplicated.setDate(_advanceOneMonth(source.date));

    setState(() => _entries.add(duplicated));
    _viewModel.clearSubmissionFeedback();
  }

  void _removeEntry(_HistoryImportEntryDraft entry) {
    if (_entries.length == 1) {
      return;
    }

    setState(() {
      _entries.remove(entry);
      entry.dispose();
    });
    _viewModel.clearSubmissionFeedback();
  }

  void _continueToReview() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _buildInput() == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    _viewModel.clearSubmissionFeedback();
    setState(() => _step = _HistoryImportFlowStep.review);
  }

  Future<void> _submit() async {
    final input = _buildInput();
    if (input == null) {
      setState(() => _step = _HistoryImportFlowStep.collect);
      return;
    }

    FocusScope.of(context).unfocus();
    final created = await _viewModel.importHistory(input);
    if (!mounted) {
      return;
    }

    if (created == null) {
      if (_viewModel.hasFieldErrors) {
        setState(() => _step = _HistoryImportFlowStep.collect);
      }
      return;
    }

    setState(() {
      _createdImport = created;
      _step = _HistoryImportFlowStep.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histórico importado com sucesso.')),
    );
  }

  void _resetDraft() {
    for (final entry in _entries) {
      entry.dispose();
    }

    setState(() {
      _entries
        ..clear()
        ..add(_newEntryDraft());
      _selectedPaymentMethod = null;
      _createdImport = null;
      _step = _HistoryImportFlowStep.collect;
    });
    _viewModel.clearSubmissionFeedback();
  }

  CreateHistoryImportInput? _buildInput() {
    final paymentMethod = _selectedPaymentMethod;
    if (paymentMethod == null || _entries.isEmpty) {
      return null;
    }

    final builtEntries = <HistoryImportEntryInput>[];
    for (final entry in _entries) {
      final amount = _parseAmount(entry.amountController.text);
      if (amount == null ||
          amount <= 0 ||
          entry.selectedCategoryId == null ||
          entry.selectedSubcategoryId == null) {
        return null;
      }

      builtEntries.add(
        HistoryImportEntryInput(
          description: entry.descriptionController.text.trim(),
          amount: amount,
          date: entry.date,
          categoryId: entry.selectedCategoryId!,
          subcategoryId: entry.selectedSubcategoryId!,
          notes: entry.notesController.text.trim(),
        ),
      );
    }

    return CreateHistoryImportInput(
      entries: builtEntries,
      paymentMethod: paymentMethod,
    );
  }

  CatalogOption? _selectedCategoryFor(_HistoryImportEntryDraft entry) {
    final selectedCategoryId = entry.selectedCategoryId;
    if (selectedCategoryId == null) {
      return null;
    }

    for (final option in _viewModel.catalogOptions) {
      if (option.id == selectedCategoryId) {
        return option;
      }
    }

    return null;
  }

  List<ExpenseReference> _subcategoryOptionsFor(
    _HistoryImportEntryDraft entry,
  ) {
    return _selectedCategoryFor(entry)?.subcategories ?? const [];
  }

  String? _selectedSubcategoryNameFor(_HistoryImportEntryDraft entry) {
    final selectedSubcategoryId = entry.selectedSubcategoryId;
    if (selectedSubcategoryId == null) {
      return null;
    }

    for (final option in _subcategoryOptionsFor(entry)) {
      if (option.id == selectedSubcategoryId) {
        return option.name;
      }
    }

    return null;
  }

  void _clearEntryFieldError(int index, String field) {
    _viewModel.clearFieldError('entries[$index].$field');
  }

  String? _entryFieldError(int index, String field) {
    return _viewModel.fieldError('entries[$index].$field');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: const RouteBackButton(fallbackRoute: '/expenses/new'),
        title: const Text('Trazer meu histórico'),
        actions: buildAuthenticatedTopBarActions(
          context: context,
          sessionController: widget.sessionController,
          currentLocation: '/history/import',
          canReviewOperations:
              widget.sessionController.currentUser?.role == 'OWNER',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return ResponsiveScrollBody(
              maxWidth: 920,
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
                  if (_step == _HistoryImportFlowStep.collect)
                    _buildCollectStep(),
                  if (_step == _HistoryImportFlowStep.review)
                    _buildReviewStep(),
                  if (_step == _HistoryImportFlowStep.success)
                    _buildSuccessStep(),
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
        key: ValueKey('history-import-loading-catalog-card'),
        title: 'Preparando a importação do seu histórico',
        message:
            'Carregando as categorias necessárias para importar seu histórico.',
        showProgress: true,
      );
    }

    if (_viewModel.loadCatalogErrorMessage != null &&
        !_viewModel.hasCatalogOptions) {
      return _StateCard(
        key: const ValueKey('history-import-catalog-error-card'),
        title: 'Não foi possível carregar o catálogo',
        message: _viewModel.loadCatalogErrorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: _viewModel.loadCatalogOptions,
      );
    }

    if (!_viewModel.hasCatalogOptions) {
      return const _StateCard(
        key: ValueKey('history-import-empty-catalog-card'),
        title: 'Catálogo indisponível',
        message:
            'Cadastre ao menos uma categoria e uma subcategoria ativas antes de trazer seu histórico.',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SummaryHeader(
                  title: 'Conte o essencial do lote',
                  subtitle:
                      'Neste fluxo você organiza despesas passadas já pagas. Primeiro escolha como esse lote foi pago; depois detalhe os itens com calma.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<HistoryImportPaymentMethod?>(
                  key: ValueKey(
                    'history-import-form-payment-method-field-${_selectedPaymentMethod?.apiValue ?? 'none'}',
                  ),
                  isExpanded: true,
                  initialValue: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Como esse lote foi pago?',
                    helperText:
                        'Neste fluxo, a forma de pagamento vale para todos os itens do lote.',
                    errorText: _viewModel.fieldError('paymentMethod'),
                  ),
                  items: [
                    const DropdownMenuItem<HistoryImportPaymentMethod?>(
                      value: null,
                      child: Text('Escolha a forma de pagamento'),
                    ),
                    for (final method in HistoryImportPaymentMethod.values)
                      DropdownMenuItem<HistoryImportPaymentMethod?>(
                        value: method,
                        child: Text(method.label),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPaymentMethod = value);
                    _viewModel.clearFieldError('paymentMethod');
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a forma de pagamento do lote.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _entries.length; index++) ...[
            _buildEntryEditor(index, _entries[index]),
            const SizedBox(height: 16),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('history-import-add-entry-button'),
                  onPressed: _viewModel.isSubmitting ? null : _addEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item em branco'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('history-import-duplicate-entry-button'),
                  onPressed: _viewModel.isSubmitting
                      ? null
                      : _duplicateLastEntry,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Duplicar último item'),
                ),
              ],
            ),
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
                  : () => context.go('/expenses/new'),
              child: const Text('Voltar ao lançamento manual'),
            ),
            primary: FilledButton.icon(
              key: const ValueKey('history-import-form-continue-button'),
              onPressed: _viewModel.isSubmitting ? null : _continueToReview,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar para revisão'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryEditor(int index, _HistoryImportEntryDraft entry) {
    final theme = Theme.of(context);
    final selectedCategory = _selectedCategoryFor(entry);
    final subcategoryOptions = _subcategoryOptionsFor(entry);

    return SectionCard(
      key: ValueKey('history-import-entry-card-${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SummaryHeader(
                  title: index == 0
                      ? 'Primeiro item do lote'
                      : 'Item ${index + 1}',
                  subtitle: index == 0
                      ? 'Comece por uma despesa passada que já foi totalmente paga.'
                      : 'Adicione outro item do histórico com os mesmos cuidados.',
                ),
              ),
              if (_entries.length > 1) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: ValueKey('history-import-entry-$index-remove-button'),
                  onPressed: _viewModel.isSubmitting
                      ? null
                      : () => _removeEntry(entry),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: ValueKey('history-import-entry-$index-description-field'),
            controller: entry.descriptionController,
            textInputAction: TextInputAction.next,
            maxLength: 140,
            decoration: InputDecoration(
              labelText: 'Como você quer identificar esse item?',
              hintText: 'Ex.: Mercado de fevereiro, aluguel de janeiro',
              errorText: _entryFieldError(index, 'description'),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Informe uma descrição para este item.';
              }
              if (trimmed.length > 140) {
                return 'Use no máximo 140 caracteres.';
              }
              return null;
            },
            onChanged: (_) => _clearEntryFieldError(index, 'description'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('history-import-entry-$index-amount-field'),
            controller: entry.amountController,
            textInputAction: TextInputAction.next,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Qual foi o valor pago?',
              hintText: 'Ex.: 189,90',
              errorText: _entryFieldError(index, 'amount'),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Informe o valor deste item.';
              }
              final amount = _parseAmount(trimmed);
              if (amount == null || amount <= 0) {
                return 'Informe um valor maior que zero.';
              }
              return null;
            },
            onChanged: (_) => _clearEntryFieldError(index, 'amount'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('history-import-entry-$index-date-field'),
            controller: entry.dateController,
            readOnly: true,
            onTap: () => _pickEntryDate(entry, index),
            decoration: InputDecoration(
              labelText: 'Quando isso aconteceu?',
              errorText: _entryFieldError(index, 'date'),
              suffixIcon: IconButton(
                tooltip: 'Selecionar data',
                onPressed: () => _pickEntryDate(entry, index),
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe a data deste item.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey(
              'history-import-entry-$index-category-field-${entry.selectedCategoryId ?? 'none'}',
            ),
            isExpanded: true,
            initialValue: entry.selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Categoria',
              errorText: _entryFieldError(index, 'categoryId'),
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
                entry.selectedCategoryId = value;
                entry.selectedSubcategoryId = null;
              });
              _clearEntryFieldError(index, 'categoryId');
              _clearEntryFieldError(index, 'subcategoryId');
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
              'history-import-entry-$index-subcategory-field-${entry.selectedSubcategoryId ?? 'none'}',
            ),
            isExpanded: true,
            initialValue: entry.selectedSubcategoryId,
            decoration: InputDecoration(
              labelText: 'Subcategoria',
              helperText: selectedCategory != null && subcategoryOptions.isEmpty
                  ? 'A categoria selecionada não possui subcategorias ativas.'
                  : null,
              errorText: _entryFieldError(index, 'subcategoryId'),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Escolha a subcategoria'),
              ),
              for (final option in subcategoryOptions)
                DropdownMenuItem<int?>(
                  value: option.id,
                  child: Text(option.name),
                ),
            ],
            onChanged: (value) {
              setState(() => entry.selectedSubcategoryId = value);
              _clearEntryFieldError(index, 'subcategoryId');
            },
            validator: (value) {
              if (value == null) {
                return 'Selecione a subcategoria.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('history-import-entry-$index-notes-field'),
            controller: entry.notesController,
            textInputAction: TextInputAction.next,
            maxLength: 255,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Observação opcional',
              hintText: 'Ex.: pago no fechamento da semana, ajuste de casa',
              errorText: _entryFieldError(index, 'notes'),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.length > 255) {
                return 'Use no maximo 255 caracteres.';
              }
              return null;
            },
            onChanged: (_) => _clearEntryFieldError(index, 'notes'),
          ),
          const SizedBox(height: 8),
          Text(
            'Esse item será gravado como despesa já paga depois da sua confirmação final.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final input = _buildInput();
    final theme = Theme.of(context);
    if (input == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DraftReviewPanel(
          key: const ValueKey('history-import-review-panel'),
          title: 'Revise antes de confirmar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confira o lote antes de confirmar. Depois disso, cada item será salvo como despesa já paga.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 16),
              _ReviewRow(
                label: 'Método de pagamento do lote',
                value: input.paymentMethod.label,
              ),
              _ReviewRow(
                label: 'Quantidade de itens',
                value: '${input.entries.length}',
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < input.entries.length; index++) ...[
                _buildReviewEntryCard(index, input.entries[index]),
                const SizedBox(height: 12),
              ],
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
                : () => setState(() => _step = _HistoryImportFlowStep.collect),
            child: const Text('Voltar e ajustar'),
          ),
          primary: FilledButton.icon(
            key: const ValueKey('history-import-review-confirm-button'),
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
                  : 'Confirmar importação',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewEntryCard(int index, HistoryImportEntryInput entry) {
    final draft = _entries[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ReviewRow(label: 'Descrição', value: entry.description),
            _ReviewRow(label: 'Valor', value: formatCurrency(entry.amount)),
            _ReviewRow(label: 'Data', value: _formatDate(entry.date)),
            _ReviewRow(
              label: 'Categoria',
              value: _selectedCategoryFor(draft)?.name ?? '-',
            ),
            _ReviewRow(
              label: 'Subcategoria',
              value: _selectedSubcategoryNameFor(draft) ?? '-',
            ),
            if ((entry.notes ?? '').trim().isNotEmpty)
              _ReviewRow(label: 'Observação', value: entry.notes!.trim()),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    final createdImport = _createdImport;
    if (createdImport == null) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      key: const ValueKey('history-import-success-card'),
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
                  title: 'Histórico importado',
                  subtitle:
                      'O lote foi salvo no espaço atual e cada item entrou como despesa já paga.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReviewRow(
            label: 'Itens importados',
            value: '${createdImport.importedCount}',
          ),
          _ReviewRow(
            label: 'Método do lote',
            value: _selectedPaymentMethod?.label ?? '-',
          ),
          const SizedBox(height: 8),
          for (
            var index = 0;
            index < createdImport.entries.length;
            index++
          ) ...[
            _buildImportedEntryCard(index, createdImport.entries[index]),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          _ActionBar(
            secondary: OutlinedButton(
              onPressed: () => context.go('/expenses'),
              child: const Text('Ver despesas importadas'),
            ),
            primary: FilledButton.icon(
              key: const ValueKey(
                'history-import-success-create-another-button',
              ),
              onPressed: _resetDraft,
              icon: const Icon(Icons.add),
              label: const Text('Importar outro lote'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportedEntryCard(int index, HistoryImportEntryRecord entry) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item importado ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ReviewRow(label: 'Descrição', value: entry.description),
            _ReviewRow(label: 'Valor', value: formatCurrency(entry.amount)),
            _ReviewRow(label: 'Data', value: _formatDate(entry.date)),
            _ReviewRow(
              label: 'Status',
              value: _formatStatusLabel(entry.status),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _advanceOneMonth(DateTime value) {
    final normalized = _normalizeDate(value);
    final lastDayOfNextMonth = DateTime(
      normalized.year,
      normalized.month + 2,
      0,
    ).day;
    final nextDay = math.min(normalized.day, lastDayOfNextMonth);
    return DateTime(normalized.year, normalized.month + 1, nextDay);
  }

  static String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final day = normalized.day.toString().padLeft(2, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    return '$day/$month/${normalized.year}';
  }

  static double? _parseAmount(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String _formatStatusLabel(String value) {
    return switch (value) {
      'PAGA' => 'Paga',
      'PAGO' => 'Pago',
      'OPEN' => 'Em aberto',
      'OVERDUE' => 'Vencida',
      _ => value,
    };
  }
}

class _HistoryImportEntryDraft {
  _HistoryImportEntryDraft({required this.id, required DateTime initialDate})
    : date = initialDate,
      dateController = TextEditingController(
        text: _HistoryImportFormScreenState._formatDate(initialDate),
      );

  final int id;
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final TextEditingController dateController;

  DateTime date;
  int? selectedCategoryId;
  int? selectedSubcategoryId;

  void setDate(DateTime value) {
    date = value;
    dateController.text = _HistoryImportFormScreenState._formatDate(value);
  }

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    notesController.dispose();
    dateController.dispose();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.step});

  final _HistoryImportFlowStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SummaryHeader(
            title: 'Trazer meu histórico',
            subtitle:
                'Um fluxo guiado para registrar, em lote, despesas passadas que já foram pagas sem complicação.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StepChip(
                label: '1. Coleta guiada',
                isActive: step == _HistoryImportFlowStep.collect,
              ),
              _StepChip(
                label: '2. Revisão',
                isActive: step == _HistoryImportFlowStep.review,
              ),
              _StepChip(
                label: '3. Confirmação',
                isActive: step == _HistoryImportFlowStep.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step == _HistoryImportFlowStep.collect
                ? 'Você monta um lote manual com uma única forma de pagamento e itens claros. Para séries simples, duplique o último item e ajuste o que mudou no mês.'
                : step == _HistoryImportFlowStep.review
                ? 'Agora confira o lote inteiro com calma. O salvamento só acontece depois da sua confirmação.'
                : 'Tudo certo. A importação histórica em lote foi concluída.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
        ],
      ),
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
