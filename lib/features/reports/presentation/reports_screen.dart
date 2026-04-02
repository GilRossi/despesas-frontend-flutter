import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';
import 'package:despesas_frontend/features/reports/presentation/reports_view_model.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.reportsRepository,
    required this.sessionController,
  });

  final ReportsRepository reportsRepository;
  final SessionController sessionController;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportsViewModel(reportsRepository: widget.reportsRepository)
      ..load();
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
          appBar: AppBar(
            leading: const RouteBackButton(fallbackRoute: '/'),
            title: const Text('Relatórios'),
            actions: buildAuthenticatedTopBarActions(
              context: context,
              sessionController: widget.sessionController,
              currentLocation: '/reports',
              canReviewOperations:
                  widget.sessionController.currentUser?.role == 'OWNER',
            ),
          ),
          body: SafeArea(
            top: false,
            child: Builder(
              builder: (context) {
                if (_viewModel.isLoading && !_viewModel.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_viewModel.errorMessage != null && !_viewModel.hasData) {
                  return _StateCard(
                    title: _viewModel.isUnauthorized
                        ? 'Sessão expirada'
                        : 'Não foi possível carregar os relatórios.',
                    message: _viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _viewModel.load,
                  );
                }

                final snapshot = _viewModel.snapshot;
                if (snapshot == null) {
                  return const SizedBox.shrink();
                }

                return RefreshIndicator(
                  onRefresh: _viewModel.load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ReportsHeroCard(
                        referenceMonth: _viewModel.referenceMonth,
                        comparePrevious: _viewModel.comparePrevious,
                        isLoading: _viewModel.isLoading,
                        onPreviousMonth: _viewModel.goToPreviousMonth,
                        onNextMonth: _viewModel.goToNextMonth,
                        onCompareChanged: _viewModel.setComparePrevious,
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _InlineMessageCard(
                          title: 'Falha ao atualizar',
                          message: _viewModel.errorMessage!,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _KpiGrid(snapshot: snapshot),
                      if (!snapshot.summary.hasData) ...[
                        const SizedBox(height: 16),
                        const _InlineMessageCard(
                          title: 'Período sem dados',
                          message:
                              'Não há despesas registradas no mês selecionado. Ajuste o período para liberar a leitura completa.',
                        ),
                      ],
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 980;
                          if (!isWide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PrimaryReportsColumn(snapshot: snapshot),
                                const SizedBox(height: 16),
                                _SecondaryReportsColumn(snapshot: snapshot),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _PrimaryReportsColumn(
                                  snapshot: snapshot,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _SecondaryReportsColumn(
                                  snapshot: snapshot,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ReportsHeroCard extends StatelessWidget {
  const _ReportsHeroCard({
    required this.referenceMonth,
    required this.comparePrevious,
    required this.isLoading,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onCompareChanged,
  });

  final DateTime referenceMonth;
  final bool comparePrevious;
  final bool isLoading;
  final Future<void> Function() onPreviousMonth;
  final Future<void> Function() onNextMonth;
  final Future<void> Function(bool value) onCompareChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
                children: [
                  Text(
                    'Leitura clara do mês financeiro',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Resumo do espaço atual com comparação mensal, distribuição por categoria e prioridades do período.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF65727B),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : onPreviousMonth,
                  child: const Text('Mês anterior'),
                ),
                FilledButton.tonal(
                  onPressed: null,
                  child: Text(_formatMonthLabel(referenceMonth)),
                ),
                OutlinedButton(
                  onPressed: isLoading ? null : onNextMonth,
                  child: const Text('Próximo mês'),
                ),
                FilterChip(
                  label: const Text('Comparar com mês anterior'),
                  selected: comparePrevious,
                  onSelected: isLoading ? null : onCompareChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final category = snapshot.summary.categoryTotals.isEmpty
        ? null
        : snapshot.summary.categoryTotals.first;
    final comparison = snapshot.comparePrevious
        ? snapshot.insights.monthComparison
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth >= 1100 ? 220.0 : 180.0;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              width: minWidth,
              label: 'Total do período',
              value: formatCurrency(snapshot.summary.totalAmount),
              meta: _periodLabel(snapshot.summary.from, snapshot.summary.to),
            ),
            _KpiCard(
              width: minWidth,
              label: 'Pago',
              value: formatCurrency(snapshot.summary.paidAmount),
              meta:
                  '${snapshot.summary.totalExpenses} lançamento(s) no período',
            ),
            _KpiCard(
              width: minWidth,
              label: 'Pendente',
              value: formatCurrency(snapshot.summary.remainingAmount),
              meta: 'Saldo a acompanhar',
            ),
            _KpiCard(
              width: minWidth,
              label: 'Maior categoria',
              value: category?.categoryName ?? '-',
              meta: category == null
                  ? 'Sem categoria relevante'
                  : '${formatCurrency(category.totalAmount)} • ${category.sharePercentage.toStringAsFixed(2)}%',
            ),
            _KpiCard(
              width: minWidth,
              label: 'Variação mensal',
              value: comparison == null
                  ? '—'
                  : '${comparison.deltaPercentage.toStringAsFixed(2)}%',
              meta: comparison == null
                  ? 'Comparação desativada'
                  : 'Delta de ${formatCurrency(comparison.deltaAmount)}',
            ),
          ],
        );
      },
    );
  }
}

class _PrimaryReportsColumn extends StatelessWidget {
  const _PrimaryReportsColumn({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComparisonCard(snapshot: snapshot),
        const SizedBox(height: 16),
        _CategoryBreakdownCard(snapshot: snapshot),
      ],
    );
  }
}

class _SecondaryReportsColumn extends StatelessWidget {
  const _SecondaryReportsColumn({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ListSectionCard<ReportTopExpense>(
          title: 'Maiores despesas',
          subtitle: 'Lançamentos mais relevantes do período.',
          items: snapshot.summary.topExpenses,
          emptyMessage: 'Sem despesas relevantes no período.',
          itemBuilder: (expense) => _TopExpenseTile(expense: expense),
        ),
        const SizedBox(height: 16),
        _ListSectionCard<ReportRecurringExpense>(
          title: 'Recorrências detectadas',
          subtitle: 'Padrões recorrentes encontrados no espaço.',
          items: snapshot.insights.recurringExpenses,
          emptyMessage: 'Nenhum padrao recorrente forte encontrado.',
          itemBuilder: (recurring) =>
              _RecurringExpenseTile(recurring: recurring),
        ),
        if (snapshot.comparePrevious) ...[
          const SizedBox(height: 16),
          _ListSectionCard<ReportIncreaseAlert>(
            title: 'Aumentos relevantes',
            subtitle: 'Categorias com salto em relação ao mês anterior.',
            items: snapshot.insights.increaseAlerts,
            emptyMessage: 'Nenhum aumento relevante no período.',
            itemBuilder: (alert) => _IncreaseAlertTile(alert: alert),
          ),
        ],
        const SizedBox(height: 16),
        _ListSectionCard<ReportRecommendation>(
          title: 'Recomendações',
          subtitle: 'Sugestões automáticas geradas pelo sistema.',
          items: snapshot.recommendations,
          emptyMessage: 'Nenhuma recomendação disponível para o período.',
          itemBuilder: (recommendation) =>
              _RecommendationTile(recommendation: recommendation),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = snapshot.comparePrevious
        ? snapshot.insights.monthComparison
        : null;
    final summary = snapshot.summary;
    final maxTotal = comparison == null
        ? (summary.totalAmount > summary.remainingAmount
              ? summary.totalAmount
              : summary.remainingAmount)
        : (comparison.currentTotal > comparison.previousTotal
              ? comparison.currentTotal
              : comparison.previousTotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comparison == null
                  ? 'Distribuição do período'
                  : 'Comparativo mensal',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              comparison == null
                  ? 'Como o mês atual está dividido entre pago e pendente.'
                  : 'Visão direta do mês atual contra o anterior.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            const SizedBox(height: 20),
            if (comparison == null) ...[
              _MetricBar(
                label: 'Pago',
                value: formatCurrency(summary.paidAmount),
                widthFactor: _widthFactor(summary.paidAmount, maxTotal),
              ),
              const SizedBox(height: 16),
              _MetricBar(
                label: 'Pendente',
                value: formatCurrency(summary.remainingAmount),
                widthFactor: _widthFactor(summary.remainingAmount, maxTotal),
                color: const Color(0xFFC9800B),
              ),
            ] else ...[
              _MetricBar(
                label: comparison.currentMonth,
                value: formatCurrency(comparison.currentTotal),
                widthFactor: _widthFactor(comparison.currentTotal, maxTotal),
              ),
              const SizedBox(height: 16),
              _MetricBar(
                label: comparison.previousMonth,
                value: formatCurrency(comparison.previousTotal),
                widthFactor: _widthFactor(comparison.previousTotal, maxTotal),
                color: const Color(0xFF3F6B75),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _widthFactor(double amount, double maxTotal) {
    if (maxTotal <= 0) {
      return 0;
    }
    return (amount / maxTotal).clamp(0, 1);
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = snapshot.summary.categoryTotals;
    final maxAmount = categories.isEmpty
        ? 0.0
        : categories
              .map((item) => item.totalAmount)
              .reduce((value, element) => value > element ? value : element);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição por categoria',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ranking do período com peso relativo e leitura rápida da categoria dominante.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            const SizedBox(height: 20),
            if (categories.isEmpty)
              Text(
                'Nenhuma categoria apareceu no período selecionado.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              )
            else
              for (final category in categories) ...[
                _CategoryBreakdownRow(
                  category: category,
                  widthFactor: maxAmount <= 0
                      ? 0
                      : (category.totalAmount / maxAmount).clamp(0, 1),
                ),
                if (category != categories.last) const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _ListSectionCard<T> extends StatelessWidget {
  const _ListSectionCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final List<T> items;
  final String emptyMessage;
  final Widget Function(T item) itemBuilder;

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
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            const SizedBox(height: 20),
            if (items.isEmpty)
              Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              )
            else
              for (final item in items) ...[
                itemBuilder(item),
                if (item != items.last) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _TopExpenseTile extends StatelessWidget {
  const _TopExpenseTile({required this.expense});

  final ReportTopExpense expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(expense.description)),
            const SizedBox(width: 12),
            Text(formatCurrency(expense.amount)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${expense.categoryName} • ${_formatDate(expense.dueDate)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF65727B)),
        ),
      ],
    );
  }
}

class _RecurringExpenseTile extends StatelessWidget {
  const _RecurringExpenseTile({required this.recurring});

  final ReportRecurringExpense recurring;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(recurring.description)),
            const SizedBox(width: 12),
            Text(formatCurrency(recurring.averageAmount)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${recurring.occurrences} ocorrência(s) • ${recurring.categoryName}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF65727B)),
        ),
      ],
    );
  }
}

class _IncreaseAlertTile extends StatelessWidget {
  const _IncreaseAlertTile({required this.alert});

  final ReportIncreaseAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(alert.categoryName)),
            const SizedBox(width: 12),
            Text(
              '+ ${formatCurrency(alert.deltaAmount)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0A7A3E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Antes: ${formatCurrency(alert.previousAmount)} • Agora: ${formatCurrency(alert.currentAmount)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recommendation});

  final ReportRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recommendation.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          recommendation.rationale,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
        const SizedBox(height: 8),
        Text(recommendation.action),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.widthFactor,
    this.color = const Color(0xFF0C7B93),
  });

  final String label;
  final String value;
  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.widthFactor,
  });

  final ReportCategoryTotal category;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(category.categoryName)),
            const SizedBox(width: 12),
            Text(formatCurrency(category.totalAmount)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C7B93),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${category.sharePercentage.toStringAsFixed(2)}% do mês • ${category.expensesCount} despesa(s)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.label,
    required this.value,
    required this.meta,
  });

  final double width;
  final String label;
  final String value;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
              const SizedBox(height: 10),
              Text(value, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                meta,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF65727B),
                ),
              ),
            ],
          ),
        ),
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

    return ResponsiveScrollBody(
      maxWidth: 600,
      centerVertically: true,
      padding: const EdgeInsets.all(20),
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

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMonthLabel(DateTime month) {
  const labels = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${labels[month.month - 1]} ${month.year}';
}

String _periodLabel(DateTime from, DateTime to) {
  return '${_formatDate(from)} a ${_formatDate(to)}';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
