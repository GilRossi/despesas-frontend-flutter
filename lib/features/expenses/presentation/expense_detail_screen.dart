import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_view_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detalhe da despesa')),
          body: SafeArea(
            top: false,
            child: Builder(
              builder: (context) {
                if (_viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_viewModel.isNotFound) {
                  return _DetailStateCard(
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

                final expense = _viewModel.expense;
                if (expense == null) {
                  return const SizedBox.shrink();
                }

                return _DetailContent(expense: expense);
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.expense});

  final ExpenseDetail expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: theme.textTheme.headlineSmall),
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
