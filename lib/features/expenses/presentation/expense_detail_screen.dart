import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_shell_scaffold.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_view_model.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_payment_form_card.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.expensesRepository,
    this.sessionController,
    this.spaceReferencesRepository,
  });

  final int expenseId;
  final ExpensesRepository expensesRepository;
  final SessionController? sessionController;
  final SpaceReferencesRepository? spaceReferencesRepository;

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
    try {
      context.go('/');
      return;
    } catch (_) {}

    try {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.pop(_resultOnClose);
      }
    } catch (_) {}
  }

  Future<void> _openEditExpense(ExpenseDetail expense) async {
    final result = await Navigator.of(context).push<ExpenseFlowResult>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          expensesRepository: widget.expensesRepository,
          sessionController: widget.sessionController,
          spaceReferencesRepository: widget.spaceReferencesRepository,
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
                'Tem certeza que deseja excluir "${expense.description}"? Essa ação não pode ser desfeita.',
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
      _resultOnClose = const ExpenseFlowResult.reload(
        message: 'Despesa excluida com sucesso.',
      );
      _close();
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
        const SnackBar(content: Text('Não foi possível excluir a despesa.')),
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

  Future<void> _confirmDeletePayment(ExpensePayment payment) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Corrigir pagamento'),
              content: Text(
                'Remover este pagamento de ${formatCurrency(payment.amount)} para registrar novamente do jeito certo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Remover pagamento'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    final success = await _viewModel.deletePayment(payment.id);
    if (!mounted) {
      return;
    }

    if (success) {
      _resultOnClose = const ExpenseFlowResult.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pagamento removido. Você já pode registrar o valor correto.',
          ),
        ),
      );
      return;
    }

    if (_viewModel.paymentErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.paymentErrorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final expense = _viewModel.expense;

        final actions = <Widget>[
          if (expense != null && !_viewModel.isLoading) ...[
            IconButton(
              tooltip: 'Editar',
              onPressed: _isDeleting ? null : () => _openEditExpense(expense),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: _isDeleting ? null : () => _confirmDelete(expense),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          ],
        ];

        Widget content;
        if (_viewModel.isLoading) {
          content = const Center(child: CircularProgressIndicator());
        } else if (_viewModel.isNotFound) {
          content = _DetailStateCard(
            title: 'Despesa não encontrada',
            message:
                'Esse lançamento pode ter sido removido ou não pertence ao espaço atual.',
            primaryActionLabel: 'Voltar às despesas',
            onPrimaryAction: _close,
          );
        } else if (_viewModel.hasError) {
          content = _DetailStateCard(
            title: 'Não foi possível carregar a despesa.',
            message: _viewModel.errorMessage!,
            primaryActionLabel: 'Tentar novamente',
            onPrimaryAction: _viewModel.load,
            secondaryActionLabel: 'Voltar às despesas',
            onSecondaryAction: _close,
          );
        } else if (expense == null) {
          content = const SizedBox.shrink();
        } else {
          content = _DetailContent(
            expense: expense,
            showPaymentForm: expense.remainingAmount > 0,
            isSubmittingPayment: _viewModel.isSubmittingPayment,
            removingPaymentId: _viewModel.removingPaymentId,
            paymentErrorMessage: _viewModel.paymentErrorMessage,
            onSubmitPayment: _handleSubmitPayment,
            onDeletePayment: _confirmDeletePayment,
          );
        }

        if (widget.sessionController != null) {
          return AuthenticatedShellScaffold(
            sessionController: widget.sessionController!,
            currentLocation: '/expenses/${widget.expenseId}',
            title: 'Detalhe da despesa',
            fallbackRoute: '/',
            fallbackResultProvider: () => _resultOnClose,
            extraActions: actions,
            body: content,
          );
        }

        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _close();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _close),
              title: const Text('Detalhe da despesa'),
              actions: actions,
            ),
            body: SafeArea(top: false, child: content),
          ),
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.expense,
    required this.showPaymentForm,
    required this.isSubmittingPayment,
    required this.removingPaymentId,
    required this.paymentErrorMessage,
    required this.onSubmitPayment,
    required this.onDeletePayment,
  });

  final ExpenseDetail expense;
  final bool showPaymentForm;
  final bool isSubmittingPayment;
  final int? removingPaymentId;
  final String? paymentErrorMessage;
  final Future<bool> Function(CreateExpensePaymentInput input) onSubmitPayment;
  final Future<void> Function(ExpensePayment payment) onDeletePayment;

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
                    label: 'Ocorrencia',
                    value: _formatDate(expense.occurredOn),
                  ),
                  _DetailField(
                    label: 'Vencimento',
                    value: expense.dueDate == null
                        ? 'Sem vencimento'
                        : _formatDate(expense.dueDate!),
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
                  if (expense.reference != null)
                    _DetailField(
                      label: 'Referência do espaço',
                      value: expense.reference!.name,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (showPaymentForm)
            ExpensePaymentFormCard(
              expense: expense,
              isSubmitting: isSubmittingPayment,
              errorMessage: paymentErrorMessage,
              onSubmit: onSubmitPayment,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esta despesa já foi quitada.',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Não existe saldo pendente para um novo pagamento. Use o histórico abaixo para conferir o que já foi registrado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF65727B),
                      ),
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
                    'Histórico de pagamentos',
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
                      _PaymentEntry(
                        payment: expense.payments[index],
                        isRemoving:
                            removingPaymentId == expense.payments[index].id,
                        onDelete: () =>
                            onDeletePayment(expense.payments[index]),
                      ),
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
                    Text('Observações', style: theme.textTheme.titleLarge),
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
    return formatExpensePaymentDate(value);
  }

  static String _formatEnumLabel(String value) {
    return formatExpenseEnumLabel(value);
  }
}

class _PaymentEntry extends StatelessWidget {
  const _PaymentEntry({
    required this.payment,
    required this.isRemoving,
    required this.onDelete,
  });

  final ExpensePayment payment;
  final bool isRemoving;
  final VoidCallback onDelete;

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
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remover pagamento',
              onPressed: isRemoving ? null : onDelete,
              icon: isRemoving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetaChip(label: _DetailContent._formatEnumLabel(payment.method)),
        const SizedBox(height: 8),
        Text(
          'Se este pagamento foi lançado errado, remova e registre novamente com o valor correto.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
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
    );
  }
}
