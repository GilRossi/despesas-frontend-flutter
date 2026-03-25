import 'package:flutter/material.dart';

class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.alignment = MainAxisAlignment.end,
  });

  final Widget primary;
  final Widget? secondary;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        if (secondary != null) ...[
          secondary!,
          const SizedBox(width: 12),
        ],
        primary,
      ],
    );
  }
}
