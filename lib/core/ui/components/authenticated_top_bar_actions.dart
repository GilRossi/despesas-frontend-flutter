import 'package:despesas_frontend/app/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<Widget> buildAuthenticatedTopBarActions({
  required BuildContext context,
  required SessionController sessionController,
  required String currentLocation,
  bool canReviewOperations = false,
}) {
  final menuEntries =
      <_TopBarMenuEntry>[
            const _TopBarMenuEntry(
              route: '/',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
            ),
            const _TopBarMenuEntry(
              route: '/expenses',
              label: 'Ver despesas',
              icon: Icons.receipt_long_outlined,
            ),
            const _TopBarMenuEntry(
              route: '/history/import',
              label: 'Trazer meu histórico',
              icon: Icons.history_outlined,
            ),
            const _TopBarMenuEntry(
              route: '/assistant',
              label: 'Assistente financeiro',
              icon: Icons.psychology_alt_outlined,
            ),
            const _TopBarMenuEntry(
              route: '/reports',
              label: 'Relatórios',
              icon: Icons.insert_chart_outlined,
            ),
            const _TopBarMenuEntry(
              route: '/change-password',
              label: 'Minha senha',
              icon: Icons.lock_outline,
            ),
            if (canReviewOperations)
              const _TopBarMenuEntry(
                route: '/household-members',
                label: 'Membros do espaço',
                icon: Icons.group_outlined,
              ),
            if (canReviewOperations)
              const _TopBarMenuEntry(
                route: '/review-operations',
                label: 'Revisões pendentes',
                icon: Icons.fact_check_outlined,
              ),
          ]
          .where(
            (entry) => !_matchesCurrentLocation(currentLocation, entry.route),
          )
          .toList();

  return [
    PopupMenuButton<String>(
      key: const ValueKey('authenticated-top-bar-menu-button'),
      tooltip: 'Menu principal',
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 248),
      icon: const Icon(Icons.menu),
      onSelected: (route) {
        if (!context.mounted) {
          return;
        }
        context.go(route);
      },
      itemBuilder: (context) {
        return [
          for (final entry in menuEntries)
            PopupMenuItem<String>(
              key: ValueKey('authenticated-top-bar-menu-item-${entry.route}'),
              value: entry.route,
              child: SizedBox(
                width: 200,
                child: Row(
                  children: [
                    Icon(entry.icon, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
    ),
    IconButton(
      key: const ValueKey('authenticated-top-bar-logout-button'),
      tooltip: 'Sair',
      onPressed: sessionController.logout,
      icon: const Icon(Icons.logout),
    ),
  ];
}

bool _matchesCurrentLocation(String currentLocation, String route) {
  if (route == '/') {
    return currentLocation == '/';
  }
  return currentLocation == route || currentLocation.startsWith('$route/');
}

class _TopBarMenuEntry {
  const _TopBarMenuEntry({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}
