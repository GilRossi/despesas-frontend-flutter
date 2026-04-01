import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
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
  bool _isCompletingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _future = widget.dashboardRepository.fetchDashboard();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.dashboardRepository.fetchDashboard();
    });
    await _future;
  }

  Future<void> _startManualFlow() async {
    if (!_isCompletingOnboarding &&
        widget.sessionController.requiresOnboarding) {
      setState(() {
        _isCompletingOnboarding = true;
      });
      try {
        await widget.sessionController.completeOnboarding();
      } catch (_) {
        // Do not block the manual flow if onboarding completion is temporarily unavailable.
      } finally {
        if (mounted) {
          setState(() {
            _isCompletingOnboarding = false;
          });
        }
      }
    }

    if (!mounted) {
      return;
    }
    context.go('/expenses/new');
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(widget.sessionController.currentUser?.name);
    final showFirstUseCard = widget.sessionController.requiresOnboarding;

    return AppScaffold(
      title: 'Dashboard',
      subtitle: firstName == null
          ? 'O que merece sua atenção hoje'
          : '$firstName, aqui está o que merece sua atenção hoje',
      actions: buildAuthenticatedTopBarActions(
        context: context,
        sessionController: widget.sessionController,
        currentLocation: '/',
        canReviewOperations:
            widget.sessionController.currentUser?.role == 'OWNER',
      ),
      body: FutureBuilder<DashboardSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DashboardLoadingState();
          }

          if (snapshot.hasError) {
            return _DashboardErrorState(onRetry: _reload);
          }

          final dashboard = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ResponsiveScrollBody(
              maxWidth: 1080,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showFirstUseCard) ...[
                    _FirstUseCard(
                      isCompletingOnboarding: _isCompletingOnboarding,
                      onStartManualFlow: _startManualFlow,
                      onOpenAssistantHelp: () =>
                          context.go('/assistant?tour=1'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DashboardHero(
                    dashboard: dashboard,
                    onNewExpenseTap: _startManualFlow,
                    onAssistantTap: () =>
                        context.go(dashboard.assistantCard.route),
                    onTourTap: () => context.go('/assistant?tour=1'),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 920;
                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SummaryMainCard(summary: dashboard.summaryMain),
                            const SizedBox(height: 16),
                            _ActionNeededCard(
                              actionNeeded: dashboard.actionNeeded,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _SummaryMainCard(
                              summary: dashboard.summaryMain,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _ActionNeededCard(
                              actionNeeded: dashboard.actionNeeded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AssistantCard(
                    assistantCard: dashboard.assistantCard,
                    onOpenAssistant: () =>
                        context.go(dashboard.assistantCard.route),
                  ),
                  const SizedBox(height: 16),
                  _RecentActivityCard(
                    recentActivity: dashboard.recentActivity,
                    onOpenRoute: context.go,
                  ),
                  if (dashboard.isOwner) ...[
                    const SizedBox(height: 16),
                    _MonthOverviewCard(
                      monthOverview: dashboard.monthOverview,
                      onOpenReports: () => context.go('/reports'),
                    ),
                    const SizedBox(height: 16),
                    _CategorySpendingCard(
                      categorySpending: dashboard.categorySpending,
                      onOpenReports: () => context.go('/reports'),
                    ),
                    const SizedBox(height: 16),
                    _HouseholdSummaryCard(
                      householdSummary: dashboard.householdSummary,
                    ),
                  ],
                  if (dashboard.isMember) ...[
                    const SizedBox(height: 16),
                    _QuickActionsCard(
                      quickActions: dashboard.quickActions,
                      onOpenRoute: context.go,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return null;
    }
    return fullName.trim().split(' ').first;
  }
}

class _FirstUseCard extends StatelessWidget {
  const _FirstUseCard({
    required this.isCompletingOnboarding,
    required this.onStartManualFlow,
    required this.onOpenAssistantHelp,
  });

  final bool isCompletingOnboarding;
  final Future<void> Function() onStartManualFlow;
  final VoidCallback onOpenAssistantHelp;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('dashboard-first-use-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primeiro uso: comece pelo lancamento manual',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'O caminho mais simples e lancar sua primeira despesa agora. O assistente continua disponivel como ajuda opcional, reabrivel e contextual.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const ValueKey('dashboard-first-use-manual-button'),
                onPressed: isCompletingOnboarding ? null : onStartManualFlow,
                icon: isCompletingOnboarding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(
                  isCompletingOnboarding
                      ? 'Abrindo lancamento...'
                      : 'Lancar minha primeira despesa',
                ),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('dashboard-first-use-assistant-button'),
                onPressed: isCompletingOnboarding ? null : onOpenAssistantHelp,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Abrir ajuda opcional'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Carregando seu dashboard...'),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.redAccent),
          const SizedBox(height: 8),
          const Text('Nao foi possivel carregar seu dashboard agora.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.dashboard,
    required this.onNewExpenseTap,
    required this.onAssistantTap,
    required this.onTourTap,
  });

  final DashboardSummary dashboard;
  final VoidCallback onNewExpenseTap;
  final VoidCallback onAssistantTap;
  final VoidCallback onTourTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = dashboard.isOwner ? 'Visao do Espaço' : 'Visao pessoal';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3B5F), Color(0xFF1C6A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 16,
        children: [
          SizedBox(
            width: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comece pelo caminho certo, sem tela fria',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A home precisa orientar de verdade: lance uma despesa, abra o assistente ou reative o tour guiado sempre que quiser revisar os primeiros passos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroBadge(label: 'Avulsa sem vencimento'),
                    _HeroBadge(label: 'Conta com vencimento'),
                    _HeroBadge(label: 'Conta fixa e historico separados'),
                  ],
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const ValueKey('dashboard-hero-new-expense-button'),
                onPressed: onNewExpenseTap,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Lancar despesa'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('dashboard-hero-assistant-button'),
                onPressed: onAssistantTap,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Abrir assistente'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('dashboard-hero-tour-button'),
                onPressed: onTourTap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver tour guiado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _SummaryMainCard extends StatelessWidget {
  const _SummaryMainCard({required this.summary});

  final DashboardSummaryMain summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Resumo principal',
            subtitle: 'Panorama rápido do mês atual',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                label: 'Mes de referência',
                value: _formatReferenceMonth(summary.referenceMonth),
                highlight: false,
              ),
              _MetricTile(
                label: 'Pago no mês',
                value: formatCurrency(summary.paidThisMonthAmount),
                highlight: true,
              ),
              _MetricTile(
                label: 'Em aberto',
                value:
                    '${summary.openCount} item(ns) · ${formatCurrency(summary.totalOpenAmount)}',
              ),
              _MetricTile(
                label: 'Vencido',
                value:
                    '${summary.overdueCount} item(ns) · ${formatCurrency(summary.totalOverdueAmount)}',
                accentColor: const Color(0xFFB84C2A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReferenceMonth(String referenceMonth) {
    if (referenceMonth.length != 7 || !referenceMonth.contains('-')) {
      return referenceMonth;
    }
    final parts = referenceMonth.split('-');
    return '${parts[1]}/${parts[0]}';
  }
}

class _ActionNeededCard extends StatelessWidget {
  const _ActionNeededCard({required this.actionNeeded});

  final DashboardActionNeeded actionNeeded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Precisa da sua ação',
            subtitle: 'O que vale priorizar agora',
          ),
          const SizedBox(height: 16),
          _CompactStatRow(
            label: 'Vencidas',
            value:
                '${actionNeeded.overdueCount} · ${formatCurrency(actionNeeded.overdueAmount)}',
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          _CompactStatRow(
            label: 'Em aberto',
            value:
                '${actionNeeded.openCount} · ${formatCurrency(actionNeeded.openAmount)}',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          if (actionNeeded.items.isEmpty)
            const _EmptySectionMessage(
              message: 'Nenhum item urgente no momento.',
            )
          else
            Column(
              children: [
                for (final item in actionNeeded.items) ...[
                  _ActionItemTile(item: item),
                  if (item != actionNeeded.items.last)
                    const Divider(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.recentActivity,
    required this.onOpenRoute,
  });

  final DashboardRecentActivity recentActivity;
  final void Function(String route) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Atividade recente',
            subtitle: 'O que acabou de acontecer no seu Espaço',
          ),
          const SizedBox(height: 16),
          if (recentActivity.items.isEmpty)
            const _EmptySectionMessage(
              message: 'Sem movimentações recentes por enquanto.',
            )
          else
            Column(
              children: [
                for (final item in recentActivity.items) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F0F0),
                      child: Icon(
                        item.type == 'PAYMENT_RECORDED'
                            ? Icons.check_circle_outline
                            : Icons.receipt_long_outlined,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.subtitle}${item.occurredAt == null ? '' : ' · ${_formatDateTime(item.occurredAt!)}'}',
                    ),
                    trailing: Text(formatCurrency(item.amount)),
                    onTap: () => onOpenRoute(item.route),
                  ),
                  if (item != recentActivity.items.last)
                    const Divider(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.assistantCard,
    required this.onOpenAssistant,
  });

  final DashboardAssistantCard assistantCard;
  final VoidCallback onOpenAssistant;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: assistantCard.title,
                  subtitle: 'Apoio rápido, tour reabrivel e próximos passos',
                ),
                const SizedBox(height: 12),
                Text(assistantCard.message),
                const SizedBox(height: 12),
                Text(
                  'Se der dúvida sobre por onde começar, abra o assistente e reative o tour guiado sem depender do onboarding inicial.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF65727B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            key: const ValueKey('dashboard-open-assistant-button'),
            onPressed: onOpenAssistant,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Abrir assistente'),
          ),
        ],
      ),
    );
  }
}

class _MonthOverviewCard extends StatelessWidget {
  const _MonthOverviewCard({
    required this.monthOverview,
    required this.onOpenReports,
  });

  final DashboardMonthOverview? monthOverview;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('dashboard-owner-month-overview-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Panorama do mês',
            subtitle: 'Leitura executiva do período atual',
          ),
          const SizedBox(height: 16),
          if (monthOverview == null)
            const _EmptySectionMessage(
              message: 'Panorama do mês indisponível agora.',
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Total do mês',
                  value: formatCurrency(monthOverview!.totalAmount),
                ),
                _MetricTile(
                  label: 'Pago',
                  value: formatCurrency(monthOverview!.paidAmount),
                ),
                _MetricTile(
                  label: 'Restante',
                  value: formatCurrency(monthOverview!.remainingAmount),
                ),
                _MetricTile(
                  label: 'Comparação',
                  value: monthOverview!.monthComparison == null
                      ? 'Sem base'
                      : '${monthOverview!.monthComparison!.deltaPercentage.toStringAsFixed(2)}%',
                ),
              ],
            ),
            if (monthOverview!.highestSpendingCategory != null) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Categoria que mais pesa'),
                subtitle: Text(
                  monthOverview!.highestSpendingCategory!.categoryName,
                ),
                trailing: Text(
                  formatCurrency(
                    monthOverview!.highestSpendingCategory!.totalAmount,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onOpenReports,
                child: const Text('Abrir relatórios'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategorySpendingCard extends StatelessWidget {
  const _CategorySpendingCard({
    required this.categorySpending,
    required this.onOpenReports,
  });

  final DashboardCategorySpending? categorySpending;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('dashboard-owner-category-spending-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Gastos por categoria',
            subtitle: 'Onde o mês está pesando mais',
          ),
          const SizedBox(height: 16),
          if (categorySpending == null || categorySpending!.items.isEmpty)
            const _EmptySectionMessage(
              message: 'Sem categorias suficientes para leitura agora.',
            )
          else ...[
            for (final item in categorySpending!.items) ...[
              _ProgressTile(
                label: item.categoryName,
                value: formatCurrency(item.totalAmount),
                percentage: item.sharePercentage,
              ),
              if (item != categorySpending!.items.last)
                const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onOpenReports,
                child: const Text('Ver leitura completa'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HouseholdSummaryCard extends StatelessWidget {
  const _HouseholdSummaryCard({required this.householdSummary});

  final DashboardHouseholdSummary? householdSummary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('dashboard-owner-household-summary-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Resumo do Espaço',
            subtitle: 'Visão rápida da estrutura do seu household',
          ),
          const SizedBox(height: 16),
          if (householdSummary == null)
            const _EmptySectionMessage(
              message: 'Resumo do Espaço indisponível no momento.',
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Membros',
                  value: householdSummary!.membersCount.toString(),
                ),
                _MetricTile(
                  label: 'Owners',
                  value: householdSummary!.ownersCount.toString(),
                ),
                _MetricTile(
                  label: 'Members',
                  value: householdSummary!.membersOnlyCount.toString(),
                ),
                _MetricTile(
                  label: 'Referências',
                  value: householdSummary!.spaceReferencesCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (householdSummary!.referencesByGroup.isEmpty)
              const _EmptySectionMessage(
                message: 'Nenhuma referência agrupada cadastrada ainda.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in householdSummary!.referencesByGroup)
                    Chip(label: Text('${item.group.label}: ${item.count}')),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.quickActions,
    required this.onOpenRoute,
  });

  final DashboardQuickActions? quickActions;
  final void Function(String route) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('dashboard-member-quick-actions-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Atalhos rápidos',
            subtitle: 'Entre direto no próximo passo',
          ),
          const SizedBox(height: 16),
          if (quickActions == null || quickActions!.items.isEmpty)
            const _EmptySectionMessage(
              message: 'Sem atalhos disponíveis agora.',
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in quickActions!.items)
                  OutlinedButton.icon(
                    key: ValueKey('dashboard-quick-action-${item.key}'),
                    onPressed: () => onOpenRoute(item.route),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(item.label),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF65727B),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.highlight = false,
    this.accentColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        accentColor ??
        (highlight ? theme.colorScheme.primary : const Color(0xFF101828));

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE8F1FF) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatRow extends StatelessWidget {
  const _CompactStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionItemTile extends StatelessWidget {
  const _ActionItemTile({required this.item});

  final DashboardActionItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _statusColor(item.status).withValues(alpha: 0.12),
        child: Icon(Icons.priority_high, color: _statusColor(item.status)),
      ),
      title: Text(item.description),
      subtitle: Text(
        '${item.status} · ${item.dueDate == null ? 'Sem vencimento' : _formatDate(item.dueDate!)}',
      ),
      trailing: Text(formatCurrency(item.amount)),
      onTap: () => context.go(item.route),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'VENCIDA' => const Color(0xFFB84C2A),
      'PARCIALMENTE_PAGA' => const Color(0xFF8A6B00),
      _ => const Color(0xFF0F5D66),
    };
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.label,
    required this.value,
    required this.percentage,
  });

  final String label;
  final String value;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$value · ${percentage.toStringAsFixed(2)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, minHeight: 8),
      ],
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month às $hour:$minute';
}
