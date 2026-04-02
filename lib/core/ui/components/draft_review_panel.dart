import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:flutter/material.dart';

class DraftReviewPanel extends StatelessWidget {
  const DraftReviewPanel({
    super.key,
    this.title = 'Revisão do rascunho',
    required this.child,
    this.onSubmit,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (onSubmit != null)
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
