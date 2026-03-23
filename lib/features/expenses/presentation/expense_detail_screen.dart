import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_view_model.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:flutter/material.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.expensesRepository,
  });

  final int expenseId;
  final ExpensesRepository expensesRepository;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late final ExpenseDetailViewModel _viewModel;
  ExpenseFlowResult? _resultOnClose;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ExpenseDetailViewModel(
      expenseId: widget.expenseId,
      expensesRepository: widget.expensesRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop(_resultOnClose);
  }

  Future<void> _openEditExpense(ExpenseDetail expense) async {
    final result = await Navigator.of(context).push<ExpenseFlowResult>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          expensesRepository: widget.expensesRepository,
          initialExpense: expense,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.shouldReload) {
      _resultOnClose = const ExpenseFlowResult.reload();
      await _viewModel.load();
    }

    if (!mounted || result.message == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message!)));
  }

  Future<void> _confirmDelete(ExpenseDetail expense) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir despesa'),
              content: Text(
                'Tem certeza que deseja excluir "${expense.description}"? Essa acao nao pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await widget.expensesRepository.deleteExpense(expense.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        const ExpenseFlowResult.reload(
          message: 'Despesa excluida com sucesso.',
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel excluir a despesa.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool> _handleSubmitPayment(CreateExpensePaymentInput input) async {
    final success = await _viewModel.registerPayment(input);
    if (!mounted) {
      return success;
    }

    if (success) {
      _resultOnClose = const ExpenseFlowResult.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento registrado com sucesso.')),
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final expense = _viewModel.expense;

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _close),
              title: const Text('Detalhe da despesa'),
              actions: [
                if (expense != null && !_viewModel.isLoading) ...[
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: _isDeleting
                        ? null
                        : () => _openEditExpense(expense),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    onPressed: _isDeleting
                        ? null
                        : () => _confirmDelete(expense),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            body: SafeArea(
              top: false,
              child: Builder(
                builder: (context) {
                  if (_viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_viewModel.isNotFound) {
                    return const _DetailStateCard(
                      title: 'Despesa nao encontrada',
                      message:
                          'Esse lancamento pode ter sido removido ou nao pertence ao household atual.',
                    );
                  }

                  if (_viewModel.hasError) {
                    return _DetailStateCard(
                      title: 'Nao foi possivel carregar a despesa.',
                      message: _viewModel.errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _viewModel.load,
                    );
                  }

                  if (expense == null) {
                    return const SizedBox.shrink();
                  }

                  return _DetailContent(
                    expense: expense,
                    isSubmittingPayment: _viewModel.isSubmittingPayment,
                    paymentErrorMessage: _viewModel.paymentErrorMessage,
                    onSubmitPayment: _handleSubmitPayment,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.expense,
    required this.isSubmittingPayment,
    required this.paymentErrorMessage,
    required this.onSubmitPayment,
  });

  final ExpenseDetail expense;
  final bool isSubmittingPayment;
  final String? paymentErrorMessage;
  final Future<bool> Function(CreateExpensePaymentInput input) onSubmitPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatCurrency(expense.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(label: _formatEnumLabel(expense.status)),
                      _MetaChip(label: _formatEnumLabel(expense.context)),
                      if (expense.overdue) const _MetaChip(label: 'Atrasada'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumo', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _DetailField(
                    label: 'Categoria',
                    value:
                        '${expense.category.name} · ${expense.subcategory.name}',
                  ),
                  _DetailField(
                    label: 'Vencimento',
                    value: _formatDate(expense.dueDate),
                  ),
                  _DetailField(
                    label: 'Pago',
                    value: formatCurrency(expense.paidAmount),
                  ),
                  _DetailField(
                    label: 'Restante',
                    value: formatCurrency(expense.remainingAmount),
                  ),
                  _DetailField(
                    label: 'Pagamentos registrados',
                    value: '${expense.paymentsCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PaymentFormCard(
            expense: expense,
            isSubmitting: isSubmittingPayment,
            errorMessage: paymentErrorMessage,
            onSubmit: onSubmitPayment,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historico de pagamentos',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (!expense.hasPayments)
                    Text(
                      'Nenhum pagamento registrado para esta despesa.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF65727B),
                      ),
                    )
                  else
                    for (
                      var index = 0;
                      index < expense.payments.length;
                      index++
                    ) ...[
                      _PaymentEntry(payment: expense.payments[index]),
                      if (index < expense.payments.length - 1) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                      ],
                    ],
                ],
              ),
            ),
          ),
          if (expense.hasNotes) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Observacoes', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      expense.notes,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
}

class _PaymentFormCard extends StatefulWidget {
  const _PaymentFormCard({
    required this.expense,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final ExpenseDetail expense;
  final bool isSubmitting;
  final String? errorMessage;
  final Future<bool> Function(CreateExpensePaymentInput input) onSubmit;

  @override
  State<_PaymentFormCard> createState() => _PaymentFormCardState();
}

class _PaymentFormCardState extends State<_PaymentFormCard> {
  static const _paymentMethods = [
    'PIX',
    'DINHEIRO',
    'DEBITO',
    'CREDITO',
    'TRANSFERENCIA',
    'BOLETO',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _paidAt;
  String _method = _paymentMethods.first;
  int _lastPaymentsCount = 0;

  bool get _isPaidOff => widget.expense.remainingAmount <= 0;

  @override
  void initState() {
    super.initState();
    _paidAt = _normalizeDate(DateTime.now());
    _lastPaymentsCount = widget.expense.paymentsCount;
  }

  @override
  void didUpdateWidget(covariant _PaymentFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expense.paymentsCount != _lastPaymentsCount) {
      _lastPaymentsCount = widget.expense.paymentsCount;
      _resetForm();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar pagamento', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _isPaidOff
                    ? 'Esta despesa ja foi quitada. O historico abaixo permanece disponivel para consulta.'
                    : 'Saldo restante: ${formatCurrency(widget.expense.remainingAmount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              if (!_isPaidOff) ...[
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('expense-payment-amount-field'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Valor pago',
                    hintText: 'Ex.: 49,90',
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 16),
                InkWell(
                  key: const ValueKey('expense-payment-date-field'),
                  onTap: widget.isSubmitting ? null : _selectPaidAt,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do pagamento',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_DetailContent._formatDate(_paidAt)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('expense-payment-method-field'),
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: 'Metodo de pagamento',
                  ),
                  items: _paymentMethods
                      .map(
                        (method) => DropdownMenuItem<String>(
                          value: method,
                          child: Text(_DetailContent._formatEnumLabel(method)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _method = value);
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('expense-payment-notes-field'),
                  controller: _notesController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 255,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes do pagamento',
                  ),
                  validator: (value) {
                    if (value != null && value.trim().length > 255) {
                      return 'As observacoes devem ter no maximo 255 caracteres.';
                    }
                    return null;
                  },
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('expense-payment-submit-button'),
                    onPressed: widget.isSubmitting ? null : _submit,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar pagamento'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o valor pago.';
    }

    final amount = _parseAmount(value);
    if (amount == null) {
      return 'Informe um valor valido.';
    }
    if (amount <= 0) {
      return 'O valor deve ser maior que zero.';
    }
    if (amount > widget.expense.remainingAmount) {
      return 'O valor nao pode ser maior que o saldo restante.';
    }
    return null;
  }

  Future<void> _selectPaidAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecionar data do pagamento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() => _paidAt = _normalizeDate(picked));
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final amount = _parseAmount(_amountController.text)!;

    final success = await widget.onSubmit(
      CreateExpensePaymentInput(
        expenseId: widget.expense.id,
        amount: amount,
        paidAt: _paidAt,
        method: _method,
        notes: _notesController.text.trim(),
      ),
    );

    if (success && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _notesController.clear();
    _paidAt = _normalizeDate(DateTime.now());
    _method = _paymentMethods.first;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  double? _parseAmount(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    return double.tryParse(normalized);
  }
}

class _PaymentEntry extends StatelessWidget {
  const _PaymentEntry({required this.payment});

  final ExpensePayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                formatCurrency(payment.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _DetailContent._formatDate(payment.paidAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetaChip(label: _DetailContent._formatEnumLabel(payment.method)),
        if (payment.hasNotes) ...[
          const SizedBox(height: 12),
          Text(
            payment.notes,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6C787C),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label),
      ),
    );
  }
}

class _DetailStateCard extends StatelessWidget {
  const _DetailStateCard({
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
