import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:flutter/material.dart';

const expensePaymentMethods = [
  'PIX',
  'DINHEIRO',
  'DEBITO',
  'CREDITO',
  'TRANSFERENCIA',
  'BOLETO',
];

class ExpensePaymentFormCard extends StatefulWidget {
  const ExpensePaymentFormCard({
    super.key,
    required this.expense,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
    this.title = 'Registrar pagamento',
  });

  final ExpenseDetail expense;
  final bool isSubmitting;
  final String? errorMessage;
  final Future<bool> Function(CreateExpensePaymentInput input) onSubmit;
  final String title;

  @override
  State<ExpensePaymentFormCard> createState() => _ExpensePaymentFormCardState();
}

class _ExpensePaymentFormCardState extends State<ExpensePaymentFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _paidAt;
  String _method = expensePaymentMethods.first;
  int _lastPaymentsCount = 0;

  bool get _isPaidOff => widget.expense.remainingAmount <= 0;

  @override
  void initState() {
    super.initState();
    _paidAt = _normalizeDate(DateTime.now());
    _lastPaymentsCount = widget.expense.paymentsCount;
    _amountController.text = _formatAmount(widget.expense.remainingAmount);
  }

  @override
  void didUpdateWidget(covariant ExpensePaymentFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expense.paymentsCount != _lastPaymentsCount ||
        widget.expense.remainingAmount != oldWidget.expense.remainingAmount) {
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
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _isPaidOff
                    ? 'Esta despesa ja foi quitada. O historico permanece disponivel para consulta.'
                    : 'Saldo restante: ${formatCurrency(widget.expense.remainingAmount)}. O valor ja vem preenchido e pode ser ajustado ate o saldo.',
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
                          child: Text(formatExpensePaymentDate(_paidAt)),
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
                  items: expensePaymentMethods
                      .map(
                        (method) => DropdownMenuItem<String>(
                          value: method,
                          child: Text(formatExpenseEnumLabel(method)),
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
    _amountController.text = _formatAmount(widget.expense.remainingAmount);
    _notesController.clear();
    _paidAt = _normalizeDate(DateTime.now());
    _method = expensePaymentMethods.first;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
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

String formatExpensePaymentDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String formatExpenseEnumLabel(String value) {
  return value
      .toLowerCase()
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
