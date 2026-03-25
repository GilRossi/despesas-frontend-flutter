import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.dashboardRepository,
    required this.sessionController,
  });

  final DashboardRepository dashboardRepository;
  final SessionController sessionController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.dashboardRepository.fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'Resumo rápido do seu Espaço',
      body: ResponsiveScrollBody(
        maxWidth: 960,
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<DashboardSummary>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 32, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Nao foi possivel carregar o resumo agora.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _future = widget.dashboardRepository.fetchSummary();
                        });
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }
            final summary = snapshot.requireData;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SectionCard(
                        child: _SummaryGrid(summary: summary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 280,
                      child: SectionCard(
                        child: _ActionNeeded(summary: summary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assistente financeiro', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Tire dúvidas rápidas sobre seus gastos e ganhos.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF65727B)),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('dashboard-open-assistant-button'),
                        onPressed: () => context.go('/assistant'),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Abrir assistente'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        label: 'Despesas',
        value: summary.totalExpenses.toString(),
        description: 'itens cadastrados',
      ),
      _MetricCard(
        label: 'Total previsto',
        value: _formatMoney(summary.totalAmount),
      ),
      _MetricCard(
        label: 'Pago',
        value: _formatMoney(summary.paidAmount),
      ),
      _MetricCard(
        label: 'Em aberto',
        value: _formatMoney(summary.remainingAmount),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final crossAxisCount = isNarrow ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 140,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.description,
  });

  final String label;
  final String value;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF58616A))),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A858D)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionNeeded extends StatelessWidget {
  const _ActionNeeded({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Precisa da sua ação', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _ActionRow(
          label: 'Vencidas',
          count: summary.overdueCount,
          amount: summary.overdueAmount,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 8),
        _ActionRow(
          label: 'Em aberto',
          count: summary.openCount,
          amount: summary.openAmount,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Use o assistente para entender o que priorizar.',
          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF65727B)),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '$count itens',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A858D)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'R\$ ${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
