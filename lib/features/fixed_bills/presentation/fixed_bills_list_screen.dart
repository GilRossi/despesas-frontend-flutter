import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FixedBillsListScreen extends StatefulWidget {
  const FixedBillsListScreen({super.key, required this.fixedBillsRepository});

  final FixedBillsRepository fixedBillsRepository;

  @override
  State<FixedBillsListScreen> createState() => _FixedBillsListScreenState();
}

class _FixedBillsListScreenState extends State<FixedBillsListScreen> {
  var _isLoading = true;
  String? _errorMessage;
  List<FixedBillRecord> _records = const [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const RouteBackButton(fallbackRoute: '/'),
        title: const Text('Minhas contas fixas'),
        actions: [
          FilledButton.tonalIcon(
            key: const ValueKey('fixed-bills-list-create-button'),
            onPressed: () => context.go('/fixed-bills/new'),
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ResponsiveScrollBody(
            maxWidth: 900,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SummaryHeader(
                        title: 'Contas fixas cadastradas',
                        subtitle:
                            'Aqui voce reencontra o que ja foi configurado como semanal ou mensal sem depender do assistente.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'A lista destaca descricao, recorrencia, valor, primeiro vencimento e referencia opcional para facilitar o reencontro.',
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
                        'Buscando as contas fixas ja cadastradas no household atual.',
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
                        'Quando voce registrar uma conta semanal ou mensal, ela aparece aqui para reencontro rapido.',
                    actionLabel: 'Cadastrar conta fixa',
                    onAction: () => context.go('/fixed-bills/new'),
                  ),
                if (!_isLoading && _errorMessage == null && _records.isNotEmpty)
                  ...[
                    for (final record in _records) ...[
                      _FixedBillCard(record: record),
                      const SizedBox(height: 12),
                    ],
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedBillCard extends StatelessWidget {
  const _FixedBillCard({required this.record});

  final FixedBillRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = _formatDate(record.firstDueDate);
    final createdAt = _formatDate(record.createdAt);

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
              _InfoChip(label: 'Primeiro vencimento $dueDate'),
              if (record.spaceReference != null)
                _InfoChip(label: 'Referencia ${record.spaceReference!.name}'),
              _InfoChip(label: 'Criada em $createdAt'),
            ],
          ),
        ],
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
          SummaryHeader(title: title, subtitle: message),
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
  final normalized = value.toLocal();
  final day = normalized.day.toString().padLeft(2, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  return '$day/$month/${normalized.year}';
}
