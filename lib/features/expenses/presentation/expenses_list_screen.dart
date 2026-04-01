import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:despesas_frontend/core/ui/components/empty_state.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_view_model.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({
    super.key,
    this.initialHighlightedExpenseId,
    required this.sessionController,
    required this.expensesRepository,
    required this.financialAssistantRepository,
    required this.householdMembersRepository,
    required this.reportsRepository,
    required this.reviewOperationsRepository,
  });

  final int? initialHighlightedExpenseId;
  final SessionController sessionController;
  final ExpensesRepository expensesRepository;
  final FinancialAssistantRepository financialAssistantRepository;
  final HouseholdMembersRepository householdMembersRepository;
  final ReportsRepository reportsRepository;
  final ReviewOperationsRepository reviewOperationsRepository;

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  late final ExpensesListViewModel _viewModel;
  int? _highlightedExpenseId;

  @override
  void initState() {
    super.initState();
    _viewModel = ExpensesListViewModel(
      expensesRepository: widget.expensesRepository,
    );
    _highlightedExpenseId =
        widget.initialHighlightedExpenseId ??
        _viewModel.pendingCreatedExpenseId;
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openCreateExpense() async {
    final result = await _pushOrNavigate<ExpenseFlowResult>(
      '/expenses/new',
      fallbackBuilder: () =>
          ExpenseFormScreen(expensesRepository: widget.expensesRepository),
    );
    await _handleFlowResult(result);
  }

  Future<void> _openExpenseDetail(ExpenseSummary expense) async {
    final result = await _pushOrNavigate<ExpenseFlowResult>(
      '/expenses/${expense.id}',
      fallbackBuilder: () => ExpenseDetailScreen(
        expenseId: expense.id,
        expensesRepository: widget.expensesRepository,
      ),
    );
    await _handleFlowResult(result);
  }

  Future<void> _handleFlowResult(ExpenseFlowResult? result) async {
    if (!mounted || result == null) {
      return;
    }

    if (result.shouldReload) {
      _highlightedExpenseId = result.expenseId;
      await _viewModel.load();
    }

    if (!mounted || result.message == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message!)));
  }

  Future<T?> _pushOrNavigate<T>(
    String route, {
    required Widget Function() fallbackBuilder,
  }) async {
    try {
      return await context.push<T>(route);
    } catch (_) {
      return Navigator.of(
        context,
      ).push<T>(MaterialPageRoute(builder: (_) => fallbackBuilder()));
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.sessionController, _viewModel]),
      builder: (context, _) {
        final user = widget.sessionController.currentUser;
        final canReviewOperations = user?.role == 'OWNER';

        return AppScaffold(
          title: 'Despesas',
          subtitle: user?.name,
          leading: const RouteBackButton(fallbackRoute: '/'),
          actions: buildAuthenticatedTopBarActions(
            context: context,
            sessionController: widget.sessionController,
            currentLocation: '/expenses',
            canReviewOperations: canReviewOperations,
          ),
          body: RefreshIndicator(
            onRefresh: _viewModel.load,
            child: ListView(
              children: [
                SectionCard(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lista principal do household',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aqui o foco e localizar, abrir e acompanhar despesas. A navegacao global continua no menu superior.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF65727B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('expenses-new-expense-button'),
                        onPressed: _openCreateExpense,
                        icon: const Icon(Icons.add),
                        label: const Text('Nova despesa'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_viewModel.isLoading && _viewModel.expenses.isEmpty) ...[
                  const SizedBox(height: 120),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_viewModel.errorMessage != null) ...[
                  SectionCard(
                    child: EmptyState(
                      title: 'Nao foi possivel carregar as despesas.',
                      message: _viewModel.errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _viewModel.load,
                    ),
                  ),
                ] else if (_viewModel.isEmpty) ...[
                  const SectionCard(
                    child: EmptyState(
                      title: 'Nenhuma despesa encontrada',
                      message:
                          'Crie a primeira despesa do household para iniciar a gestao pelo Flutter Web.',
                    ),
                  ),
                ] else ...[
                  if (_viewModel.isLoading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Despesas do household atual',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cada card destaca status, vencimento e saldo restante para reduzir leitura desnecessaria.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF65727B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final expense in _viewModel.expenses) ...[
                    _ExpenseCard(
                      expense: expense,
                      highlighted: expense.id == _highlightedExpenseId,
                      onTap: () => _openExpenseDetail(expense),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.highlighted,
  });

  final ExpenseSummary expense;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = expense.dueDate == null
        ? null
        : '${expense.dueDate!.day.toString().padLeft(2, '0')}/${expense.dueDate!.month.toString().padLeft(2, '0')}/${expense.dueDate!.year}';
    final statusTone = _ExpenseStatusTone.fromExpense(expense, theme);
    final financialSummary = _buildFinancialSummary(expense);

    return Card(
      color: highlighted ? const Color(0xFFF5FBF8) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${expense.category.name} · ${expense.subcategory.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF65727B),
                          ),
                        ),
                        if (expense.reference != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Referencia: ${expense.reference!.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF65727B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(expense.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaChip(
                        label: statusTone.label,
                        backgroundColor: statusTone.backgroundColor,
                        textColor: statusTone.textColor,
                        borderColor: statusTone.borderColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: dueDate == null ? 'Sem vencimento' : 'Vence em $dueDate',
                  ),
                  _MetaChip(
                    label: financialSummary,
                  ),
                  if (highlighted) const _MetaChip(label: 'Recem criada'),
                  if (expense.overdue) const _MetaChip(label: 'Atrasada'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFinancialSummary(ExpenseSummary expense) {
    if (expense.remainingAmount <= 0) {
      return 'Pago ${formatCurrency(expense.paidAmount)}';
    }
    if (expense.paidAmount > 0) {
      return 'Pago ${formatCurrency(expense.paidAmount)} · Restam ${formatCurrency(expense.remainingAmount)}';
    }
    return 'Restante ${formatCurrency(expense.remainingAmount)}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.backgroundColor = const Color(0xFFF0F4F3),
    this.textColor = const Color(0xFF32414B),
    this.borderColor = Colors.transparent,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _ExpenseStatusTone {
  const _ExpenseStatusTone({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  factory _ExpenseStatusTone.fromExpense(ExpenseSummary expense, ThemeData theme) {
    if (expense.overdue) {
      return const _ExpenseStatusTone(
        label: 'Atrasada',
        backgroundColor: Color(0xFFFDECEC),
        textColor: Color(0xFFB42318),
        borderColor: Color(0xFFF9D3D0),
      );
    }

    return switch (expense.status) {
      'PAGA' => const _ExpenseStatusTone(
        label: 'Paga',
        backgroundColor: Color(0xFFE9F7EF),
        textColor: Color(0xFF0F7B44),
        borderColor: Color(0xFFC7EBD4),
      ),
      'PARCIALMENTE_PAGA' => _ExpenseStatusTone(
        label: 'Parcialmente paga',
        backgroundColor: const Color(0xFFFFF4E5),
        textColor: const Color(0xFFB54708),
        borderColor: const Color(0xFFF3D3A6),
      ),
      'PREVISTA' => _ExpenseStatusTone(
        label: 'Prevista',
        backgroundColor: const Color(0xFFF3F4F6),
        textColor: const Color(0xFF475467),
        borderColor: const Color(0xFFD5D8DD),
      ),
      _ => _ExpenseStatusTone(
        label: 'Em aberto',
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        textColor: theme.colorScheme.primary,
        borderColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
    };
  }
}
