import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_view_model.dart';
import 'package:flutter/material.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({
    super.key,
    required this.expensesRepository,
    this.initialExpense,
  });

  final ExpensesRepository expensesRepository;
  final ExpenseDetail? initialExpense;

  bool get isEditing => initialExpense != null;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
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
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  late final ExpenseFormViewModel _viewModel;
  late DateTime _dueDate;
  late String _context;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  bool get _isEditing => widget.isEditing;

  ExpenseDetail? get _initialExpense => widget.initialExpense;

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

  @override
  void initState() {
    super.initState();
    _viewModel = ExpenseFormViewModel(
      expensesRepository: widget.expensesRepository,
    );
    _seedInitialValues();
    _loadCatalogOptions();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedInitialValues() {
    final expense = _initialExpense;
    _descriptionController.text = expense?.description ?? '';
    _amountController.text = expense == null
        ? ''
        : expense.amount.toStringAsFixed(2).replaceAll('.', ',');
    _notesController.text = expense?.notes ?? '';
    _dueDate = _normalizeDate(expense?.dueDate ?? DateTime.now());
    _dueDateController.text = _formatDate(_dueDate);
    _context = expense?.context ?? _contexts.first;
    _selectedCategoryId = expense?.category.id;
    _selectedSubcategoryId = expense?.subcategory.id;
  }

  Future<void> _loadCatalogOptions() async {
    await _viewModel.loadCatalogOptions();
    if (!mounted) {
      return;
    }

    setState(_syncCatalogSelection);
  }

  void _syncCatalogSelection() {
    final options = _viewModel.catalogOptions;
    if (options.isEmpty) {
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      return;
    }

    CatalogOption selectedCategory = options.first;
    if (_selectedCategoryId != null) {
      for (final option in options) {
        if (option.id == _selectedCategoryId) {
          selectedCategory = option;
          break;
        }
      }
    }

    _selectedCategoryId = selectedCategory.id;

    if (selectedCategory.subcategories.isEmpty) {
      _selectedSubcategoryId = null;
      return;
    }

    ExpenseReference selectedSubcategory = selectedCategory.subcategories.first;
    if (_selectedSubcategoryId != null) {
      for (final option in selectedCategory.subcategories) {
        if (option.id == _selectedSubcategoryId) {
          selectedSubcategory = option;
          break;
        }
      }
    }

    _selectedSubcategoryId = selectedSubcategory.id;
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(_dueDate.year - 5),
      lastDate: DateTime(_dueDate.year + 10),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _dueDate = _normalizeDate(picked);
      _dueDateController.text = _formatDate(_dueDate);
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid ||
        _selectedCategoryId == null ||
        _selectedSubcategoryId == null) {
      setState(() {});
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null) {
      setState(() {});
      return;
    }

    final input = SaveExpenseInput(
      description: _descriptionController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      context: _context,
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId!,
      notes: _notesController.text,
    );

    final success = _isEditing
        ? await _viewModel.updateExpense(
            expenseId: _initialExpense!.id,
            input: input,
          )
        : await _viewModel.createExpense(input);

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pop(
      ExpenseFlowResult.reload(
        message: _isEditing
            ? 'Despesa atualizada com sucesso.'
            : 'Despesa criada com sucesso.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar despesa' : 'Nova despesa'),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoadingCatalog && !_viewModel.hasCatalogOptions) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_viewModel.loadErrorMessage != null &&
                !_viewModel.hasCatalogOptions) {
              return _FormStateCard(
                title: 'Nao foi possivel carregar o catalogo.',
                message: _viewModel.loadErrorMessage!,
                actionLabel: 'Tentar novamente',
                onAction: _loadCatalogOptions,
              );
            }

            if (!_viewModel.hasCatalogOptions) {
              return const _FormStateCard(
                title: 'Catalogo indisponivel',
                message:
                    'Cadastre ao menos uma categoria e subcategoria ativas antes de criar despesas.',
              );
            }

            final category = _selectedCategory;
            final hasSubcategories = _subcategoryOptions.isNotEmpty;

            return ResponsiveScrollBody(
              maxWidth: 760,
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'Atualize os dados principais da despesa.'
                              : 'Cadastre uma nova despesa para o household atual.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF58616A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Descricao',
                            errorText: _viewModel.fieldError('description'),
                          ),
                          maxLength: 140,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe a descricao da despesa.';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              _viewModel.clearFieldError('description'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Valor',
                            hintText: 'Ex.: 129,90',
                            errorText: _viewModel.fieldError('amount'),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o valor da despesa.';
                            }
                            final amount = _parseAmount(value);
                            if (amount == null || amount <= 0) {
                              return 'Informe um valor maior que zero.';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              _viewModel.clearFieldError('amount'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dueDateController,
                          readOnly: true,
                          onTap: _pickDueDate,
                          decoration: InputDecoration(
                            labelText: 'Vencimento',
                            errorText: _viewModel.fieldError('dueDate'),
                            suffixIcon: IconButton(
                              tooltip: 'Selecionar data',
                              onPressed: _pickDueDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe a data de vencimento.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey('context-$_context'),
                          initialValue: _context,
                          decoration: InputDecoration(
                            labelText: 'Contexto',
                            errorText: _viewModel.fieldError('context'),
                          ),
                          items: [
                            for (final contextValue in _contexts)
                              DropdownMenuItem(
                                value: contextValue,
                                child: Text(_formatEnumLabel(contextValue)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _context = value);
                            _viewModel.clearFieldError('context');
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          key: ValueKey('category-$_selectedCategoryId'),
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            errorText: _viewModel.fieldError('categoryId'),
                          ),
                          items: [
                            for (final option in _viewModel.catalogOptions)
                              DropdownMenuItem(
                                value: option.id,
                                child: Text(option.name),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedCategoryId = value;
                              final category = _selectedCategory;
                              _selectedSubcategoryId =
                                  category != null &&
                                      category.subcategories.isNotEmpty
                                  ? category.subcategories.first.id
                                  : null;
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
                        DropdownButtonFormField<int>(
                          key: ValueKey(
                            'subcategory-$hasSubcategories-$_selectedSubcategoryId',
                          ),
                          initialValue: hasSubcategories
                              ? _selectedSubcategoryId
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Subcategoria',
                            helperText: category != null && !hasSubcategories
                                ? 'A categoria selecionada nao possui subcategorias ativas.'
                                : null,
                            errorText: _viewModel.fieldError('subcategoryId'),
                          ),
                          items: [
                            for (final option in _subcategoryOptions)
                              DropdownMenuItem(
                                value: option.id,
                                child: Text(option.name),
                              ),
                          ],
                          onChanged: !hasSubcategories
                              ? null
                              : (value) {
                                  setState(
                                    () => _selectedSubcategoryId = value,
                                  );
                                  _viewModel.clearFieldError('subcategoryId');
                                },
                          validator: (value) {
                            if (!hasSubcategories) {
                              return 'Selecione outra categoria com subcategorias ativas.';
                            }
                            if (value == null) {
                              return 'Selecione a subcategoria.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Observacoes',
                            alignLabelWithHint: true,
                            errorText: _viewModel.fieldError('notes'),
                          ),
                          maxLength: 255,
                          onChanged: (_) => _viewModel.clearFieldError('notes'),
                        ),
                        if (_viewModel.submitErrorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _viewModel.submitErrorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : _submit,
                                child: _viewModel.isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isEditing ? 'Salvar' : 'Criar despesa',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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

  static String _formatEnumLabel(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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

class _FormStateCard extends StatelessWidget {
  const _FormStateCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScrollBody(
      maxWidth: 560,
      padding: const EdgeInsets.all(20),
      centerVertically: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
