import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/empty_state.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
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
import 'package:go_router/go_router.dart';

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
    final result = await _pushOrNavigate<ExpenseFlowResult>(
      '/expenses/new',
      fallbackBuilder: () => ExpenseFormScreen(
        expensesRepository: widget.expensesRepository,
      ),
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

  Future<void> _openReviewOperations() async {
    await _goOrPush(
      '/review-operations',
      fallbackBuilder: () => ReviewOperationsListScreen(
        reviewOperationsRepository: widget.reviewOperationsRepository,
      ),
    );
  }

  Future<void> _openReports() async {
    await _goOrPush(
      '/reports',
      fallbackBuilder: () =>
          ReportsScreen(reportsRepository: widget.reportsRepository),
    );
  }

  Future<void> _openFinancialAssistant() async {
    await _goOrPush(
      '/assistant',
      fallbackBuilder: () => FinancialAssistantScreen(
        financialAssistantRepository: widget.financialAssistantRepository,
        sessionController: widget.sessionController,
      ),
    );
  }

  Future<void> _openHouseholdMembers() async {
    await _goOrPush(
      '/household-members',
      fallbackBuilder: () => HouseholdMembersScreen(
        householdMembersRepository: widget.householdMembersRepository,
      ),
    );
  }

  Future<void> _openChangePassword() async {
    await _goOrPush(
      '/change-password',
      fallbackBuilder: () =>
          ChangePasswordScreen(sessionController: widget.sessionController),
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

  Future<T?> _pushOrNavigate<T>(
    String route, {
    required Widget Function() fallbackBuilder,
  }) async {
    try {
      return await context.push<T>(route);
    } catch (_) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(builder: (_) => fallbackBuilder()),
      );
    }
  }

  Future<void> _goOrPush(
    String route, {
    required Widget Function() fallbackBuilder,
  }) async {
    try {
      context.go(route);
      return;
    } catch (_) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => fallbackBuilder()),
      );
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
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gestao principal de despesas',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (user?.email != null)
                              Text(
                                user!.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF65727B),
                                ),
                              ),
                            const SizedBox(height: 6),
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
                        key: const ValueKey('expenses-new-expense-button'),
                        onPressed: _openCreateExpense,
                        icon: const Icon(Icons.add),
                        label: const Text('Nova despesa'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('expenses-assistant-button'),
                        onPressed: _openFinancialAssistant,
                        icon: const Icon(Icons.psychology_alt_outlined),
                        label: const Text('Assistente financeiro'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('expenses-reports-button'),
                        onPressed: _openReports,
                        icon: const Icon(Icons.insert_chart_outlined),
                        label: const Text('Relatorios'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('expenses-security-button'),
                        onPressed: _openChangePassword,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Minha senha'),
                      ),
                      if (canReviewOperations)
                        OutlinedButton.icon(
                          key: const ValueKey('expenses-members-button'),
                          onPressed: _openHouseholdMembers,
                          icon: const Icon(Icons.group_outlined),
                          label: const Text('Membros do household'),
                        ),
                      if (canReviewOperations)
                        OutlinedButton.icon(
                          key: const ValueKey(
                            'expenses-review-operations-button',
                          ),
                          onPressed: _openReviewOperations,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Review operations'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_viewModel.isLoading) ...[
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
