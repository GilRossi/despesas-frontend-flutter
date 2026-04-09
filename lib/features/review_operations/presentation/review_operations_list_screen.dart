import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_shell_scaffold.dart';
import 'package:despesas_frontend/core/utils/currency_formatter.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_screen.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_flow_result.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReviewOperationsListScreen extends StatefulWidget {
  const ReviewOperationsListScreen({
    super.key,
    required this.reviewOperationsRepository,
    required this.sessionController,
  });

  final ReviewOperationsRepository reviewOperationsRepository;
  final SessionController sessionController;

  @override
  State<ReviewOperationsListScreen> createState() =>
      _ReviewOperationsListScreenState();
}

class _ReviewOperationsListScreenState
    extends State<ReviewOperationsListScreen> {
  late final ReviewOperationsListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReviewOperationsListViewModel(
      reviewOperationsRepository: widget.reviewOperationsRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openDetail(EmailIngestionReviewSummary review) async {
    final result = await _pushOrNavigate<ReviewOperationsFlowResult>(
      '/review-operations/${review.ingestionId}',
      fallbackBuilder: () => ReviewOperationDetailScreen(
        ingestionId: review.ingestionId,
        reviewOperationsRepository: widget.reviewOperationsRepository,
        sessionController: widget.sessionController,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.shouldReload) {
      await _viewModel.load(page: _viewModel.currentPage);
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
      listenable: _viewModel,
      builder: (context, _) {
        return AuthenticatedShellScaffold(
          sessionController: widget.sessionController,
          currentLocation: '/review-operations',
          title: 'Revisões pendentes',
          fallbackRoute: '/',
          body: RefreshIndicator(
            onRefresh: () => _viewModel.load(page: _viewModel.currentPage),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revisões pendentes do espaço',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Revise as importações que ainda dependem de decisão humana antes da confirmação final.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF65727B),
                          ),
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
                    title: _viewModel.isForbidden
                        ? 'Acesso negado'
                        : _viewModel.isUnauthorized
                        ? 'Sessão expirada'
                        : 'Não foi possível carregar as revisões.',
                    message: _viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: () =>
                        _viewModel.load(page: _viewModel.currentPage),
                  ),
                ] else if (_viewModel.isEmpty) ...[
                  const _StateCard(
                    title: 'Nenhuma revisão pendente',
                    message:
                        'Não há importações aguardando decisão manual no espaço atual.',
                  ),
                ] else ...[
                  Text(
                    'Revisões encontradas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  for (final review in _viewModel.reviews) ...[
                    _ReviewSummaryCard(
                      review: review,
                      onTap: () => _openDetail(review),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  _PaginationBar(viewModel: _viewModel),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.review, required this.onTap});

  final EmailIngestionReviewSummary review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          review.subject,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review.sender,
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
                        formatCurrency(review.totalAmount),
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
              Text(review.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(label: review.merchantOrPayee),
                  _MetaChip(label: _formatEnumLabel(review.classification)),
                  _MetaChip(
                    label: 'Confiança ${review.confidence.toStringAsFixed(2)}',
                  ),
                  _MetaChip(label: review.sourceAccount),
                  _MetaChip(label: _formatDateTime(review.receivedAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.viewModel});

  final ReviewOperationsListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 12,
          children: [
            Text(
              'Página ${viewModel.currentPage + 1} de ${viewModel.totalPages == 0 ? 1 : viewModel.totalPages} · ${viewModel.totalElements} pendência(s)',
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: viewModel.hasPreviousPage
                      ? viewModel.loadPreviousPage
                      : null,
                  child: const Text('Anterior'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: viewModel.hasNextPage
                      ? viewModel.loadNextPage
                      : null,
                  child: const Text('Próxima'),
                ),
              ],
            ),
          ],
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
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
