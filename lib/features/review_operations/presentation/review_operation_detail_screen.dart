import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_view_model.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_flow_result.dart';
import 'package:flutter/material.dart';

class ReviewOperationDetailScreen extends StatefulWidget {
  const ReviewOperationDetailScreen({
    super.key,
    required this.ingestionId,
    required this.reviewOperationsRepository,
  });

  final int ingestionId;
  final ReviewOperationsRepository reviewOperationsRepository;

  @override
  State<ReviewOperationDetailScreen> createState() =>
      _ReviewOperationDetailScreenState();
}

class _ReviewOperationDetailScreenState
    extends State<ReviewOperationDetailScreen> {
  late final ReviewOperationDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReviewOperationDetailViewModel(
      ingestionId: widget.ingestionId,
      reviewOperationsRepository: widget.reviewOperationsRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final result = await _viewModel.approve();
    if (!mounted) {
      return;
    }

    if (result == null) {
      if (_viewModel.actionErrorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_viewModel.actionErrorMessage!)));
      }
      return;
    }

    Navigator.of(context).pop(
      ReviewOperationsFlowResult.reload(
        message: 'Pendencia aprovada com sucesso.',
      ),
    );
  }

  Future<void> _reject() async {
    final result = await _viewModel.reject();
    if (!mounted) {
      return;
    }

    if (result == null) {
      if (_viewModel.actionErrorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_viewModel.actionErrorMessage!)));
      }
      return;
    }

    Navigator.of(context).pop(
      ReviewOperationsFlowResult.reload(
        message: 'Pendencia rejeitada com sucesso.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detalhe da review')),
          body: SafeArea(
            top: false,
            child: Builder(
              builder: (context) {
                if (_viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_viewModel.isNotFound) {
                  return const _StateCard(
                    title: 'Pendencia nao encontrada',
                    message:
                        'Esse item pode ter sido resolvido ou nao pertence ao household atual.',
                  );
                }

                if (_viewModel.hasError) {
                  return _StateCard(
                    title: _viewModel.isForbidden
                        ? 'Acesso negado'
                        : _viewModel.isUnauthorized
                        ? 'Sessao expirada'
                        : 'Nao foi possivel carregar a review.',
                    message: _viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _viewModel.load,
                  );
                }

                final detail = _viewModel.detail;
                if (detail == null) {
                  return const SizedBox.shrink();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                                detail.subject,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                detail.summary,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MetaChip(label: detail.sourceAccount),
                                  _MetaChip(
                                    label: _formatEnumLabel(
                                      detail.classification,
                                    ),
                                  ),
                                  _MetaChip(
                                    label:
                                        'Confianca ${detail.confidence.toStringAsFixed(2)}',
                                  ),
                                  _MetaChip(
                                    label: _formatEnumLabel(
                                      detail.finalDecision,
                                    ),
                                  ),
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
                              Text(
                                'Dados da ingestao',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _DetailField(
                                label: 'Remetente',
                                value: detail.sender,
                              ),
                              _DetailField(
                                label: 'Recebido em',
                                value: _formatDateTime(detail.receivedAt),
                              ),
                              _DetailField(
                                label: 'Favorecido',
                                value: detail.merchantOrPayee,
                              ),
                              _DetailField(
                                label: 'Valor total',
                                value: formatCurrency(detail.totalAmount),
                              ),
                              _DetailField(
                                label: 'Moeda',
                                value: detail.currency,
                              ),
                              _DetailField(
                                label: 'Categoria sugerida',
                                value:
                                    '${detail.suggestedCategoryName} · ${detail.suggestedSubcategoryName}',
                              ),
                              if (detail.dueDate != null)
                                _DetailField(
                                  label: 'Vencimento',
                                  value: _formatDate(detail.dueDate!),
                                ),
                              if (detail.occurredOn != null)
                                _DetailField(
                                  label: 'Ocorrido em',
                                  value: _formatDate(detail.occurredOn!),
                                ),
                              _DetailField(
                                label: 'Decisao desejada',
                                value: _formatEnumLabel(detail.desiredDecision),
                              ),
                              _DetailField(
                                label: 'Motivo da decisao',
                                value: _formatEnumLabel(detail.decisionReason),
                              ),
                              _DetailField(
                                label: 'Referencia bruta',
                                value: detail.rawReference,
                              ),
                              _DetailField(
                                label: 'Mensagem externa',
                                value: detail.externalMessageId,
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
                                'Itens extraidos',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (!detail.hasItems)
                                Text(
                                  'Nenhum item estruturado foi extraido para esta ingestao.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF65727B),
                                  ),
                                )
                              else
                                for (final item in detail.items) ...[
                                  _ReviewItemTile(item: item),
                                  if (item != detail.items.last) ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            runSpacing: 12,
                            spacing: 12,
                            children: [
                              OutlinedButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : _reject,
                                child: const Text('Rejeitar'),
                              ),
                              FilledButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : _approve,
                                child: _viewModel.isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Aprovar'),
                              ),
                            ],
                          ),
                        ),
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

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({required this.item});

  final EmailIngestionReviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.description, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          formatCurrency(item.amount),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (item.quantity != null) ...[
          const SizedBox(height: 4),
          Text('Quantidade: ${item.quantity}'),
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
          Text(value.isEmpty ? '-' : value, style: theme.textTheme.titleMedium),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
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
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatEnumLabel(String value) {
  if (value.trim().isEmpty) {
    return '-';
  }

  return value
      .toLowerCase()
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
