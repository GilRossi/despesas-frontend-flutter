import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveScrollBody extends StatelessWidget {
  const ResponsiveScrollBody({
    super.key,
    required this.child,
    this.controller,
    this.maxWidth = double.infinity,
    this.padding = const EdgeInsets.all(20),
    this.centerVertically = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final Widget child;
  final ScrollController? controller;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool centerVertically;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - resolvedPadding.horizontal,
        );
        final bodyWidth = math.min(maxWidth, availableWidth);
        final minHeight = math
            .max(0.0, constraints.maxHeight - resolvedPadding.vertical)
            .toDouble();

        return SingleChildScrollView(
          controller: controller,
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: resolvedPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Align(
              alignment: centerVertically
                  ? Alignment.center
                  : Alignment.topCenter,
              child: SizedBox(
                width: bodyWidth,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
