import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_operational_status.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FixedBillsListScreen extends StatefulWidget {
  const FixedBillsListScreen({
    super.key,
    required this.fixedBillsRepository,
    required this.sessionController,
  });

  final FixedBillsRepository fixedBillsRepository;
  final SessionController sessionController;

  @override
  State<FixedBillsListScreen> createState() => _FixedBillsListScreenState();
}

class _FixedBillsListScreenState extends State<FixedBillsListScreen> {
  var _isLoading = true;
  String? _errorMessage;
  List<FixedBillRecord> _records = const [];
  int? _busyRecordId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await widget.fixedBillsRepository.listFixedBills();
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Nao foi possivel carregar suas contas fixas agora.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchExpense(FixedBillRecord record) async {
    setState(() => _busyRecordId = record.id);
    try {
      final createdExpense = await widget.fixedBillsRepository.launchNextExpense(
        record.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Despesa gerada a partir de "${record.description}" e enviada para Despesas.',
          ),
        ),
      );
      context.go('/expenses/${createdExpense.id}');
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
        const SnackBar(
          content: Text('Nao foi possivel lancar a proxima despesa agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRecordId = null);
      }
    }
  }

  Future<void> _confirmDelete(FixedBillRecord record) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir conta fixa'),
              content: Text(
                'Excluir a regra "${record.description}" para impedir novos lancamentos automaticos desta recorrencia? As despesas ja geradas continuam em Despesas.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir regra'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busyRecordId = record.id);
    try {
      await widget.fixedBillsRepository.deleteFixedBill(record.id);
      if (!mounted) {
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conta fixa "${record.description}" removida. As despesas ja lancadas foram preservadas.',
          ),
        ),
      );
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
        const SnackBar(
          content: Text('Nao foi possivel excluir a conta fixa agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRecordId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final user = widget.sessionController.currentUser;
        final canReviewOperations = user?.role == 'OWNER';
        final theme = Theme.of(context);

        return AppScaffold(
          title: 'Contas fixas',
          subtitle: user?.name,
          leading: const RouteBackButton(fallbackRoute: '/'),
          actions: buildAuthenticatedTopBarActions(
            context: context,
            sessionController: widget.sessionController,
            currentLocation: '/fixed-bills',
            canReviewOperations: canReviewOperations,
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                              'Minhas contas fixas',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aqui o foco e localizar, ajustar e acompanhar regras recorrentes. O lancamento real continua em Despesas quando voce usa "Lancar despesa".',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF65727B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('fixed-bills-list-create-button'),
                        onPressed: () => context.go('/fixed-bills/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar conta fixa'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const _StateCard(
                    key: ValueKey('fixed-bills-list-loading-card'),
                    title: 'Carregando contas fixas',
                    message:
                        'Buscando regras recorrentes, proximos vencimentos e ultimo lancamento operacional.',
                    showProgress: true,
                  ),
                if (_errorMessage != null)
                  _StateCard(
                    key: const ValueKey('fixed-bills-list-error-card'),
                    title: 'Nao foi possivel abrir suas contas fixas',
                    message: _errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _load,
                  ),
                if (!_isLoading && _errorMessage == null && _records.isEmpty)
                  _StateCard(
                    key: const ValueKey('fixed-bills-list-empty-card'),
                    title: 'Nenhuma conta fixa cadastrada ainda',
                    message:
                        'Quando voce registrar uma regra semanal ou mensal, ela aparece aqui para acompanhamento e lancamento operacional.',
                    actionLabel: 'Cadastrar conta fixa',
                    onAction: () => context.go('/fixed-bills/new'),
                  ),
                if (!_isLoading && _errorMessage == null && _records.isNotEmpty)
                  ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contas fixas do household atual',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cada card destaca status, proximo vencimento e acoes da regra para manter o mesmo eixo visual de Despesas.',
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
                    for (final record in _records) ...[
                      _FixedBillCard(
                        record: record,
                        isBusy: _busyRecordId == record.id,
                        onLaunchExpense: () => _launchExpense(record),
                        onEdit: () => context.go('/fixed-bills/${record.id}/edit'),
                        onDelete: () => _confirmDelete(record),
                        onOpenLatestExpense: record.lastGeneratedExpense == null
                            ? null
                            : () => context.go(
                                '/expenses/${record.lastGeneratedExpense!.expenseId}',
                              ),
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

class _FixedBillCard extends StatelessWidget {
  const _FixedBillCard({
    required this.record,
    required this.isBusy,
    required this.onLaunchExpense,
    required this.onEdit,
    required this.onDelete,
    this.onOpenLatestExpense,
  });

  final FixedBillRecord record;
  final bool isBusy;
  final VoidCallback onLaunchExpense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLatestExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextDueDate = _formatDate(record.nextDueDate);
    final firstDueDate = _formatDate(record.firstDueDate);
    final createdAt = _formatDate(record.createdAt);
    final latestExpense = record.lastGeneratedExpense;

    return SectionCard(
      key: ValueKey('fixed-bills-list-item-${record.id}'),
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
                      record.description,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.category.name} · ${record.subcategory.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5D6872),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatCurrency(record.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: record.frequency.label),
              _StatusChip(status: record.operationalStatus),
              _InfoChip(label: _nextDueLabel(record)),
              _InfoChip(label: 'Primeiro vencimento $firstDueDate'),
              if (record.spaceReference != null)
                _InfoChip(label: 'Referencia ${record.spaceReference!.name}'),
              _InfoChip(label: 'Criada em $createdAt'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            record.operationalStatus == FixedBillOperationalStatus.overdue
                ? 'A regra esta atrasada desde $nextDueDate. Use "Lancar despesa" para criar a proxima despesa operacional em Despesas.'
                : record.operationalStatus ==
                      FixedBillOperationalStatus.dueToday
                ? 'Esta regra vence hoje. Use "Lancar despesa" para mandar o lancamento real para Despesas.'
                : 'Proximo vencimento em $nextDueDate. A despesa real so entra em Despesas quando voce lancar esta regra.',
          ),
          if (latestExpense != null) ...[
            const SizedBox(height: 12),
            Text(
              'Ultima despesa gerada em ${_formatDate(latestExpense.dueDate)}.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: ValueKey('fixed-bills-launch-expense-${record.id}'),
                onPressed: isBusy ? null : onLaunchExpense,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  isBusy ? 'Processando...' : 'Lancar despesa',
                ),
              ),
              OutlinedButton.icon(
                key: ValueKey('fixed-bills-edit-${record.id}'),
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar regra'),
              ),
              if (onOpenLatestExpense != null)
                OutlinedButton.icon(
                  key: ValueKey('fixed-bills-open-latest-expense-${record.id}'),
                  onPressed: isBusy ? null : onOpenLatestExpense,
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Abrir ultima despesa'),
                ),
              TextButton.icon(
                key: ValueKey('fixed-bills-delete-${record.id}'),
                onPressed: isBusy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir regra'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nextDueLabel(FixedBillRecord record) {
    final nextDueDate = _formatDate(record.nextDueDate);
    return switch (record.operationalStatus) {
      FixedBillOperationalStatus.overdue => 'Atrasada desde $nextDueDate',
      FixedBillOperationalStatus.dueToday => 'Vence hoje',
      FixedBillOperationalStatus.upcoming => 'Proximo vencimento $nextDueDate',
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FixedBillOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = switch (status) {
      FixedBillOperationalStatus.overdue => (
        const Color(0xFFFCE8E6),
        const Color(0xFFB3261E),
      ),
      FixedBillOperationalStatus.dueToday => (
        const Color(0xFFFFF3E0),
        const Color(0xFF9A5B00),
      ),
      FixedBillOperationalStatus.upcoming => (
        const Color(0xFFE8F5E9),
        const Color(0xFF1B5E20),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          status.label,
          style: TextStyle(fontWeight: FontWeight.w600, color: foregroundColor),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
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
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65727B),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 6),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
