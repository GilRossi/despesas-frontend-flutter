import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void popOrGo(BuildContext context, String fallbackRoute, {Object? result}) {
  try {
    context.go(fallbackRoute);
    return;
  } catch (_) {}

  final navigator = Navigator.maybeOf(context);
  if (navigator != null && navigator.canPop()) {
    navigator.pop(result);
    return;
  }

  try {
    context.go(fallbackRoute);
  } catch (_) {}
}

class RouteBackButton extends StatelessWidget {
  const RouteBackButton({super.key, required this.fallbackRoute, this.tooltip});

  final String fallbackRoute;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      onPressed: () => popOrGo(context, fallbackRoute),
    );
  }
}

class RoutePopScope<T> extends StatelessWidget {
  const RoutePopScope({
    super.key,
    required this.fallbackRoute,
    required this.child,
    this.resultProvider,
  });

  final String fallbackRoute;
  final Widget child;
  final T? Function()? resultProvider;

  @override
  Widget build(BuildContext context) {
    return PopScope<T>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          popOrGo(context, fallbackRoute, result: resultProvider?.call());
        }
      },
      child: child,
    );
  }
}
