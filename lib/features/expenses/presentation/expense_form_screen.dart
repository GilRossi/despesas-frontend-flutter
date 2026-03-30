import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_view_model.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _ExpenseLaunchMode { oneOff, dueDated }

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({
    super.key,
    required this.expensesRepository,
    this.spaceReferencesRepository,
    this.initialExpense,
    this.standalone = false,
  });

  final ExpensesRepository expensesRepository;
  final SpaceReferencesRepository? spaceReferencesRepository;
  final ExpenseDetail? initialExpense;
  final bool standalone;

  bool get isEditing => initialExpense != null;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _occurredOnController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  late final ExpenseFormViewModel _viewModel;
  late DateTime _occurredOn;
  DateTime? _dueDate;
  late _ExpenseLaunchMode _launchMode;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedSpaceReferenceId;
  _ExpenseCreateSuccessState? _successState;

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
    _viewModel = ExpenseFormViewModel(
      expensesRepository: widget.expensesRepository,
      spaceReferencesRepository: widget.spaceReferencesRepository,
    );
    _seedInitialValues();
    _loadDependencies();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _occurredOnController.dispose();
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
    _occurredOn = _normalizeDate(expense?.occurredOn ?? DateTime.now());
    _occurredOnController.text = _formatDate(_occurredOn);
    _dueDate = expense?.dueDate == null
        ? null
        : _normalizeDate(expense!.dueDate!);
    _dueDateController.text = _dueDate == null ? '' : _formatDate(_dueDate!);
    _launchMode = expense?.dueDate == null
        ? _ExpenseLaunchMode.oneOff
        : _ExpenseLaunchMode.dueDated;
    _selectedCategoryId = expense?.category.id;
    _selectedSubcategoryId = expense?.subcategory.id;
    _selectedSpaceReferenceId = expense?.reference?.id;
  }

  Future<void> _loadDependencies() async {
    await Future.wait([
      _viewModel.loadCatalogOptions(),
      _viewModel.loadReferences(),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _syncCatalogSelection();
      _syncReferenceSelection();
    });
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

  void _syncReferenceSelection() {
    if (_selectedSpaceReferenceId == null || _viewModel.references.isEmpty) {
      return;
    }

    final referenceExists = _viewModel.references.any(
      (reference) => reference.id == _selectedSpaceReferenceId,
    );
    if (!referenceExists) {
      _selectedSpaceReferenceId = null;
    }
  }

  Future<void> _pickOccurredOn() async {
    final picked = await _pickDate(initialDate: _occurredOn);
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _occurredOn = picked;
      _occurredOnController.text = _formatDate(_occurredOn);
      if (_launchMode == _ExpenseLaunchMode.oneOff) {
        _dueDate = null;
        _dueDateController.clear();
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDate(initialDate: _dueDate ?? _occurredOn);
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _dueDate = picked;
      _dueDateController.text = _formatDate(picked);
      _launchMode = _ExpenseLaunchMode.dueDated;
    });
  }

  Future<DateTime?> _pickDate({required DateTime initialDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 5),
      lastDate: DateTime(initialDate.year + 10),
    );
    return picked == null ? null : _normalizeDate(picked);
  }

  void _setLaunchMode(_ExpenseLaunchMode mode) {
    setState(() {
      _launchMode = mode;
      if (mode == _ExpenseLaunchMode.oneOff) {
        _dueDate = null;
        _dueDateController.clear();
      } else {
        _dueDate ??= _occurredOn;
        _dueDateController.text = _formatDate(_dueDate!);
      }
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
      occurredOn: _occurredOn,
      dueDate: _launchMode == _ExpenseLaunchMode.dueDated ? _dueDate : null,
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId!,
      spaceReferenceId: _selectedSpaceReferenceId,
      notes: _notesController.text,
    );

    final createdExpense = _isEditing
        ? null
        : await _viewModel.createExpense(input);
    final updated = _isEditing
        ? await _viewModel.updateExpense(
            expenseId: _initialExpense!.id,
            input: input,
          )
        : createdExpense != null;

    if (!mounted || !updated) {
      return;
    }

    if (widget.standalone && !_isEditing && createdExpense != null) {
      setState(() {
        _successState = _ExpenseCreateSuccessState(
          description: createdExpense.description,
          amount: createdExpense.amount,
          hasDueDate: createdExpense.hasDueDate,
        );
      });
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

  void _startAnotherExpense() {
    setState(() {
      _successState = null;
      _seedInitialValues();
      _syncCatalogSelection();
      _syncReferenceSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successState = _successState;
    final title = _isEditing
        ? 'Editar despesa'
        : widget.standalone
        ? 'Lancar despesa'
        : 'Nova despesa';

    return RoutePopScope<Object?>(
      fallbackRoute: '/expenses',
      child: Scaffold(
        appBar: AppBar(
          leading: const RouteBackButton(fallbackRoute: '/expenses'),
          title: Text(title),
        ),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (successState != null) {
                return _ExpenseFormSuccessState(
                  successState: successState,
                  onCreateAnother: _startAnotherExpense,
                  onOpenExpenses: () => context.go('/expenses'),
                );
              }

              if (_viewModel.isLoadingCatalog &&
                  !_viewModel.hasCatalogOptions) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_viewModel.loadErrorMessage != null &&
                  !_viewModel.hasCatalogOptions) {
                return _FormStateCard(
                  title: 'Nao foi possivel carregar o catalogo.',
                  message: _viewModel.loadErrorMessage!,
                  actionLabel: 'Tentar novamente',
                  onAction: _loadDependencies,
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
                maxWidth: 820,
                padding: const EdgeInsets.all(20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                ? 'Ajuste o lancamento e mantenha o dado coerente com o que realmente aconteceu.'
                                : 'Escolha o tipo de lancamento e registre a despesa do jeito certo, sem forcar vencimento quando ele nao existe.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF58616A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FlowGuidanceCard(
                            onOpenFixedBills: () =>
                                context.go('/fixed-bills/new'),
                            onOpenHistoryImport: () =>
                                context.go('/history/import'),
                            onOpenReferences: () =>
                                context.go('/space/references'),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Como essa despesa entra no sistema?',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 560) {
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Avulsa / pontual'),
                                      avatar: const Icon(
                                        Icons.flash_on_outlined,
                                      ),
                                      selected:
                                          _launchMode ==
                                          _ExpenseLaunchMode.oneOff,
                                      onSelected: (_) => _setLaunchMode(
                                        _ExpenseLaunchMode.oneOff,
                                      ),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Com vencimento'),
                                      avatar: const Icon(Icons.event_outlined),
                                      selected:
                                          _launchMode ==
                                          _ExpenseLaunchMode.dueDated,
                                      onSelected: (_) => _setLaunchMode(
                                        _ExpenseLaunchMode.dueDated,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return SegmentedButton<_ExpenseLaunchMode>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: _ExpenseLaunchMode.oneOff,
                                    label: Text('Avulsa / pontual'),
                                    icon: Icon(Icons.flash_on_outlined),
                                  ),
                                  ButtonSegment(
                                    value: _ExpenseLaunchMode.dueDated,
                                    label: Text('Com vencimento'),
                                    icon: Icon(Icons.event_outlined),
                                  ),
                                ],
                                selected: {_launchMode},
                                onSelectionChanged: (selection) {
                                  final mode = selection.first;
                                  _setLaunchMode(mode);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFDCE5E1),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _launchMode == _ExpenseLaunchMode.oneOff
                                    ? 'Use avulsa/pontual para casos como combustivel, mercado rapido ou qualquer gasto do dia que nao tenha vencimento formal.'
                                    : 'Use com vencimento quando existe uma data clara para pagar ou acompanhar atraso.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF58616A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            key: const ValueKey(
                              'expense-form-description-field',
                            ),
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
                            key: const ValueKey('expense-form-amount-field'),
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
                            key: const ValueKey(
                              'expense-form-occurred-on-field',
                            ),
                            controller: _occurredOnController,
                            readOnly: true,
                            onTap: _pickOccurredOn,
                            decoration: InputDecoration(
                              labelText: 'Data da ocorrencia',
                              errorText: _viewModel.fieldError('occurredOn'),
                              suffixIcon: IconButton(
                                tooltip: 'Selecionar data',
                                onPressed: _pickOccurredOn,
                                icon: const Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe a data em que isso aconteceu.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_launchMode == _ExpenseLaunchMode.dueDated)
                            TextFormField(
                              key: const ValueKey(
                                'expense-form-due-date-field',
                              ),
                              controller: _dueDateController,
                              readOnly: true,
                              onTap: _pickDueDate,
                              decoration: InputDecoration(
                                labelText: 'Vencimento',
                                helperText:
                                    'Use quando existir uma data clara para pagar.',
                                errorText: _viewModel.fieldError('dueDate'),
                                suffixIcon: IconButton(
                                  tooltip: 'Selecionar data',
                                  onPressed: _pickDueDate,
                                  icon: const Icon(
                                    Icons.event_available_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (_launchMode !=
                                    _ExpenseLaunchMode.dueDated) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe a data de vencimento.';
                                }
                                return null;
                              },
                            )
                          else
                            _InlineInfoCard(
                              title: 'Sem vencimento obrigatório',
                              message:
                                  'Esta despesa vai usar a data da ocorrencia como referencia principal e nao sera tratada como vencida automaticamente.',
                            ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            key: ValueKey(
                              'expense-form-space-reference-field-${_selectedSpaceReferenceId ?? 'none'}',
                            ),
                            initialValue: _selectedSpaceReferenceId,
                            decoration: InputDecoration(
                              labelText: 'Referencia do Espaco',
                              helperText: _viewModel.hasReferences
                                  ? 'Opcional. Use quando o gasto estiver ligado a casa, veiculo, cliente, projeto ou outra referencia cadastrada.'
                                  : _viewModel.loadReferencesErrorMessage ??
                                        'Nenhuma referencia cadastrada ainda. Voce pode seguir sem isso ou abrir o Espaço para cadastrar.',
                              errorText: _viewModel.fieldError(
                                'spaceReferenceId',
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sem referencia'),
                              ),
                              for (final reference in _viewModel.references)
                                DropdownMenuItem<int?>(
                                  value: reference.id,
                                  child: Text(
                                    '${reference.name} · ${reference.type.label}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSpaceReferenceId = value);
                              _viewModel.clearFieldError('spaceReferenceId');
                            },
                          ),
                          if (_selectedReference != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text(_selectedReference!.name)),
                                Chip(
                                  label: Text(
                                    _selectedReference!.typeGroup.label,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                            key: const ValueKey('expense-form-notes-field'),
                            controller: _notesController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Observacoes',
                              alignLabelWithHint: true,
                              errorText: _viewModel.fieldError('notes'),
                            ),
                            maxLength: 255,
                            onChanged: (_) =>
                                _viewModel.clearFieldError('notes'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Opcional. Use para posto, motivo, detalhes do gasto ou alguma anotacao util.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF65727B),
                            ),
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stackButtons = constraints.maxWidth < 540;
                              final cancelButton = OutlinedButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : () => widget.standalone
                                          ? context.go('/expenses')
                                          : Navigator.of(context).maybePop(),
                                child: Text(
                                  widget.standalone
                                      ? 'Ver despesas'
                                      : 'Cancelar',
                                ),
                              );
                              final submitButton = FilledButton(
                                key: const ValueKey(
                                  'expense-form-submit-button',
                                ),
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
                              );

                              if (stackButtons) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    cancelButton,
                                    const SizedBox(height: 12),
                                    submitButton,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: cancelButton),
                                  const SizedBox(width: 12),
                                  Expanded(child: submitButton),
                                ],
                              );
                            },
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

  static double? _parseAmount(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}

class _FlowGuidanceCard extends StatelessWidget {
  const _FlowGuidanceCard({
    required this.onOpenFixedBills,
    required this.onOpenHistoryImport,
    required this.onOpenReferences,
  });

  final VoidCallback onOpenFixedBills;
  final VoidCallback onOpenHistoryImport;
  final VoidCallback onOpenReferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget buildActionButton({
      required VoidCallback onPressed,
      required IconData icon,
      required String label,
      required bool expanded,
    }) {
      final button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );

      if (!expanded) {
        return button;
      }

      return SizedBox(width: double.infinity, child: button);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antes de lancar, confirme o tipo certo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Despesa avulsa e pontual fica aqui. Conta fixa vai para contas fixas. Lancamento antigo ou lote passado vai para historico. Referencia do Espaco pode ser criada antes ou escolhida aqui quando existir.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF58616A),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackButtons = constraints.maxWidth < 360;
                final buttons = [
                  buildActionButton(
                    onPressed: onOpenFixedBills,
                    icon: Icons.repeat_outlined,
                    label: 'Conta fixa',
                    expanded: stackButtons,
                  ),
                  buildActionButton(
                    onPressed: onOpenHistoryImport,
                    icon: Icons.history_outlined,
                    label: 'Historico',
                    expanded: stackButtons,
                  ),
                  buildActionButton(
                    onPressed: onOpenReferences,
                    icon: Icons.place_outlined,
                    label: 'Referencias',
                    expanded: stackButtons,
                  ),
                ];

                if (stackButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < buttons.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        buttons[index],
                      ],
                    ],
                  );
                }

                return Wrap(spacing: 10, runSpacing: 10, children: buttons);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF58616A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCreateSuccessState {
  const _ExpenseCreateSuccessState({
    required this.description,
    required this.amount,
    required this.hasDueDate,
  });

  final String description;
  final double amount;
  final bool hasDueDate;
}

class _ExpenseFormSuccessState extends StatelessWidget {
  const _ExpenseFormSuccessState({
    required this.successState,
    required this.onCreateAnother,
    required this.onOpenExpenses,
  });

  final _ExpenseCreateSuccessState successState;
  final VoidCallback onCreateAnother;
  final VoidCallback onOpenExpenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = successState.hasDueDate
        ? 'com vencimento'
        : 'avulso sem vencimento';

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
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                'Despesa lancada com sucesso',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '"${successState.description}" entrou como lancamento $typeLabel por R\$ ${successState.amount.toStringAsFixed(2).replaceAll('.', ',')}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se quiser, voce pode registrar a proxima sem voltar para a lista.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey(
                  'expense-form-success-create-another-button',
                ),
                onPressed: onCreateAnother,
                child: const Text('Lancar outra'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey(
                  'expense-form-success-open-expenses-button',
                ),
                onPressed: onOpenExpenses,
                child: const Text('Ver despesas'),
              ),
            ],
          ),
        ),
      ),
    );
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
