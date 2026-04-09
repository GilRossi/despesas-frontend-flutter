import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_top_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthenticatedShellScaffold extends StatelessWidget {
  const AuthenticatedShellScaffold({
    super.key,
    required this.sessionController,
    required this.currentLocation,
    required this.body,
    this.title,
    this.subtitle,
    this.fallbackRoute,
    this.leading,
    this.extraActions,
    this.floatingActionButton,
    this.fallbackResultProvider,
    this.padding = const EdgeInsets.all(20),
  });

  final SessionController sessionController;
  final String currentLocation;
  final Widget body;
  final String? title;
  final String? subtitle;
  final String? fallbackRoute;
  final Widget? leading;
  final List<Widget>? extraActions;
  final Widget? floatingActionButton;
  final Object? Function()? fallbackResultProvider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scaffold = AppScaffold(
      title: title,
      subtitle: subtitle,
      leading: leading ?? _buildLeading(context),
      actions: [
        ...?extraActions,
        ...buildAuthenticatedTopBarActions(
          context: context,
          sessionController: sessionController,
          currentLocation: currentLocation,
          canReviewOperations: sessionController.currentUser?.role == 'OWNER',
        ),
      ],
      floatingActionButton: floatingActionButton,
      padding: padding,
      body: body,
    );

    if (fallbackRoute == null) {
      return scaffold;
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) {
          _navigateToFallback(context);
        }
      },
      child: scaffold,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (fallbackRoute == null) {
      return null;
    }
    return IconButton(
      key: const ValueKey('authenticated-shell-back-button'),
      tooltip: 'Voltar',
      icon: const BackButtonIcon(),
      onPressed: () => _navigateToFallback(context),
    );
  }

  void _navigateToFallback(BuildContext context) {
    try {
      context.go(fallbackRoute!);
      return;
    } catch (_) {}

    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop(fallbackResultProvider?.call());
    }
  }
}
