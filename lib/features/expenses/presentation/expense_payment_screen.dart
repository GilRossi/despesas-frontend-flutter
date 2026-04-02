import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_view_model.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_payment_form_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpensePaymentScreen extends StatefulWidget {
  const ExpensePaymentScreen({
    super.key,
    required this.expenseId,
    required this.expensesRepository,
  });

  final int expenseId;
  final ExpensesRepository expensesRepository;

  @override
  State<ExpensePaymentScreen> createState() => _ExpensePaymentScreenState();
}

class _ExpensePaymentScreenState extends State<ExpensePaymentScreen> {
  late final ExpenseDetailViewModel _viewModel;
  _ExpensePaymentSuccessState? _successState;

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

  Future<void> _reload() {
    return _viewModel.load();
  }

  Future<bool> _handleSubmit(CreateExpensePaymentInput input) async {
    final success = await _viewModel.registerPayment(input);
    if (!mounted || !success) {
      return success;
    }

    final updatedExpense = _viewModel.expense;
    if (updatedExpense == null) {
      return false;
    }

    setState(() {
      _successState = _ExpensePaymentSuccessState(
        description: updatedExpense.description,
        paidAmount: input.amount,
        remainingAmount: updatedExpense.remainingAmount,
        paidOff: updatedExpense.remainingAmount <= 0,
      );
    });

    return true;
  }

  void _openDashboard() {
    context.go('/');
  }

  void _openExpenses() {
    context.go('/expenses');
  }

  @override
  Widget build(BuildContext context) {
    return RoutePopScope<Object?>(
      fallbackRoute: '/expenses',
      child: AppScaffold(
        title: 'Registrar pagamento',
        subtitle: 'Quitar uma despesa existente com rapidez',
        leading: const RouteBackButton(fallbackRoute: '/expenses'),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final successState = _successState;
            if (successState != null) {
              return _ExpensePaymentSuccessView(
                successState: successState,
                onOpenExpenses: _openExpenses,
                onOpenDashboard: _openDashboard,
              );
            }

            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_viewModel.isNotFound) {
              return _PaymentStateCard(
                title: 'Despesa não encontrada',
                message:
                    'Não foi possível abrir este pagamento porque a despesa não existe ou não pertence ao espaço atual.',
                primaryActionLabel: 'Ver despesas',
                onPrimaryAction: _openExpenses,
                secondaryActionLabel: 'Voltar ao dashboard',
                onSecondaryAction: _openDashboard,
              );
            }

            if (_viewModel.hasError) {
              return _PaymentStateCard(
                title: 'Não foi possível abrir o fluxo de pagamento.',
                message: _viewModel.errorMessage!,
                primaryActionLabel: 'Tentar novamente',
                onPrimaryAction: _reload,
                secondaryActionLabel: 'Voltar ao dashboard',
                onSecondaryAction: _openDashboard,
              );
            }

            final expense = _viewModel.expense;
            if (expense == null) {
              return const SizedBox.shrink();
            }

            if (expense.remainingAmount <= 0) {
              return ResponsiveScrollBody(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ExpensePaymentSummaryCard(expense: expense),
                    const SizedBox(height: 16),
                    _PaymentStateCard(
                      title: 'Despesa já quitada',
                      message:
                          'Não existe saldo pendente para registrar. Se precisar, acompanhe o histórico em Despesas.',
                      primaryActionLabel: 'Ver despesas',
                      onPrimaryAction: _openExpenses,
                      secondaryActionLabel: 'Voltar ao dashboard',
                      onSecondaryAction: _openDashboard,
                    ),
                  ],
                ),
              );
            }

            return ResponsiveScrollBody(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ExpensePaymentSummaryCard(expense: expense),
                  const SizedBox(height: 16),
                  ExpensePaymentFormCard(
                    expense: expense,
                    isSubmitting: _viewModel.isSubmittingPayment,
                    errorMessage: _viewModel.paymentErrorMessage,
                    onSubmit: _handleSubmit,
                    title: 'Confirmar pagamento',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpensePaymentSummaryCard extends StatelessWidget {
  const _ExpensePaymentSummaryCard({required this.expense});

  final ExpenseDetail expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.description, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  label: 'Saldo',
                  value: formatCurrency(expense.remainingAmount),
                ),
                _SummaryChip(
                  label: 'Vencimento',
                  value: expense.dueDate == null
                      ? 'Sem vencimento'
                      : formatExpensePaymentDate(expense.dueDate!),
                ),
                _SummaryChip(
                  label: 'Status',
                  value: formatExpenseEnumLabel(expense.status),
                ),
                _SummaryChip(label: 'Método sugerido', value: 'Pix'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _ExpensePaymentSuccessState {
  const _ExpensePaymentSuccessState({
    required this.description,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paidOff,
  });

  final String description;
  final double paidAmount;
  final double remainingAmount;
  final bool paidOff;
}

class _ExpensePaymentSuccessView extends StatelessWidget {
  const _ExpensePaymentSuccessView({
    required this.successState,
    required this.onOpenExpenses,
    required this.onOpenDashboard,
  });

  final _ExpensePaymentSuccessState successState;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScrollBody(
      maxWidth: 560,
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
                successState.paidOff
                    ? 'Despesa quitada com sucesso'
                    : 'Pagamento registrado com sucesso',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                successState.paidOff
                    ? '"${successState.description}" foi quitada com um pagamento de ${formatCurrency(successState.paidAmount)}.'
                    : '"${successState.description}" recebeu um pagamento de ${formatCurrency(successState.paidAmount)}. Restam ${formatCurrency(successState.remainingAmount)} em aberto.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('expense-payment-success-open-expenses'),
                onPressed: onOpenExpenses,
                child: const Text('Ver despesas'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('expense-payment-success-open-dashboard'),
                onPressed: onOpenDashboard,
                child: const Text('Voltar ao dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStateCard extends StatelessWidget {
  const _PaymentStateCard({
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                if (primaryActionLabel != null && onPrimaryAction != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: onPrimaryAction,
                        child: Text(primaryActionLabel!),
                      ),
                      if (secondaryActionLabel != null &&
                          onSecondaryAction != null)
                        OutlinedButton(
                          onPressed: onSecondaryAction,
                          child: Text(secondaryActionLabel!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
