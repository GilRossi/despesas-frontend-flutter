import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_view_model.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_screen.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/household_members/presentation/household_members_screen.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/presentation/reports_screen.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_screen.dart';
import 'package:flutter/material.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({
    super.key,
    required this.sessionController,
    required this.expensesRepository,
    required this.financialAssistantRepository,
    required this.householdMembersRepository,
    required this.reportsRepository,
    required this.reviewOperationsRepository,
  });

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

  @override
  void initState() {
    super.initState();
    _viewModel = ExpensesListViewModel(
      expensesRepository: widget.expensesRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _logout() {
    return widget.sessionController.logout();
  }

  Future<void> _openCreateExpense() async {
    final result = await Navigator.of(context).push<ExpenseFlowResult>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormScreen(expensesRepository: widget.expensesRepository),
      ),
    );
    await _handleFlowResult(result);
  }

  Future<void> _openExpenseDetail(ExpenseSummary expense) async {
    final result = await Navigator.of(context).push<ExpenseFlowResult>(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          expenseId: expense.id,
          expensesRepository: widget.expensesRepository,
        ),
      ),
    );
    await _handleFlowResult(result);
  }

  Future<void> _openReviewOperations() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReviewOperationsListScreen(
          reviewOperationsRepository: widget.reviewOperationsRepository,
        ),
      ),
    );
  }

  Future<void> _openReports() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReportsScreen(reportsRepository: widget.reportsRepository),
      ),
    );
  }

  Future<void> _openFinancialAssistant() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FinancialAssistantScreen(
          financialAssistantRepository: widget.financialAssistantRepository,
        ),
      ),
    );
  }

  Future<void> _openHouseholdMembers() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HouseholdMembersScreen(
          householdMembersRepository: widget.householdMembersRepository,
        ),
      ),
    );
  }

  Future<void> _handleFlowResult(ExpenseFlowResult? result) async {
    if (!mounted || result == null) {
      return;
    }

    if (result.shouldReload) {
      await _viewModel.load();
    }

    if (!mounted || result.message == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message!)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.sessionController, _viewModel]),
      builder: (context, _) {
        final user = widget.sessionController.currentUser;
        final canReviewOperations = user?.role == 'OWNER';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Despesas'),
            actions: [
              IconButton(
                tooltip: 'Assistente financeiro',
                onPressed: _openFinancialAssistant,
                icon: const Icon(Icons.psychology_alt_outlined),
              ),
              IconButton(
                tooltip: 'Relatorios',
                onPressed: _openReports,
                icon: const Icon(Icons.insert_chart_outlined),
              ),
              if (canReviewOperations)
                IconButton(
                  tooltip: 'Membros do household',
                  onPressed: _openHouseholdMembers,
                  icon: const Icon(Icons.group_outlined),
                ),
              if (canReviewOperations)
                IconButton(
                  tooltip: 'Review operations',
                  onPressed: _openReviewOperations,
                  icon: const Icon(Icons.fact_check_outlined),
                ),
              IconButton(
                tooltip: 'Nova despesa',
                onPressed: _openCreateExpense,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Sessao ativa',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF65727B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: _viewModel.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 16,
                        spacing: 16,
                        children: [
                          SizedBox(
                            width: 420,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gestao principal de despesas',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Crie, acompanhe, edite e remova despesas do household atual sem voltar ao legado.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF65727B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _openCreateExpense,
                            icon: const Icon(Icons.add),
                            label: const Text('Nova despesa'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openFinancialAssistant,
                            icon: const Icon(Icons.psychology_alt_outlined),
                            label: const Text('Assistente financeiro'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openReports,
                            icon: const Icon(Icons.insert_chart_outlined),
                            label: const Text('Relatorios'),
                          ),
                          if (canReviewOperations)
                            OutlinedButton.icon(
                              onPressed: _openHouseholdMembers,
                              icon: const Icon(Icons.group_outlined),
                              label: const Text('Membros do household'),
                            ),
                          if (canReviewOperations)
                            OutlinedButton.icon(
                              onPressed: _openReviewOperations,
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Review operations'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_viewModel.isLoading) ...[
                    const SizedBox(height: 120),
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_viewModel.errorMessage != null) ...[
                    _StateCard(
                      title: 'Nao foi possivel carregar as despesas.',
                      message: _viewModel.errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _viewModel.load,
                    ),
                  ] else if (_viewModel.isEmpty) ...[
                    const _StateCard(
                      title: 'Nenhuma despesa encontrada',
                      message:
                          'Crie a primeira despesa do household para iniciar a gestao pelo Flutter Web.',
                    ),
                  ] else ...[
                    Text(
                      'Despesas do household atual',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final expense in _viewModel.expenses) ...[
                      _ExpenseCard(
                        expense: expense,
                        onTap: () => _openExpenseDetail(expense),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onTap});

  final ExpenseSummary expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate =
        '${expense.dueDate.day.toString().padLeft(2, '0')}/${expense.dueDate.month.toString().padLeft(2, '0')}/${expense.dueDate.year}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(label: 'Vence em $dueDate'),
                  _MetaChip(label: expense.status),
                  _MetaChip(label: expense.context),
                  if (expense.overdue) const _MetaChip(label: 'Atrasada'),
                ],
              ),
            ],
          ),
        ),
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

class _StateCard extends StatelessWidget {
  const _StateCard({
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
    );
  }
}
