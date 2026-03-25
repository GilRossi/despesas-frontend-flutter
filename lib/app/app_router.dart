import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/app/splash_screen.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter({
  required SessionController sessionController,
  required ExpensesRepository expensesRepository,
  required FinancialAssistantRepository financialAssistantRepository,
  required HouseholdMembersRepository householdMembersRepository,
  required PlatformAdminRepository platformAdminRepository,
  required ReportsRepository reportsRepository,
  required ReviewOperationsRepository reviewOperationsRepository,
  required Widget splashScreen,
  required Widget Function() loginScreenBuilder,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: sessionController,
    redirect: (context, state) {
      final status = sessionController.status;
      final loggingIn = state.matchedLocation == '/login';
      final inSplash = state.matchedLocation == '/splash';

      if (status == SessionStatus.bootstrapping) {
        return inSplash ? null : '/splash';
      }

      if (status == SessionStatus.unauthenticated) {
        return loggingIn ? null : '/login';
      }

      // Authenticated
      if (loggingIn || inSplash) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => splashScreen,
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => loginScreenBuilder(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AuthenticatedShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final userRole = sessionController.currentUser?.role;
              final isPlatformAdmin = userRole == 'PLATFORM_ADMIN';

              if (isPlatformAdmin) {
                return PlatformAdminScreen(
                  sessionController: sessionController,
                  platformAdminRepository: platformAdminRepository,
                );
              }

              return ExpensesListScreen(
                sessionController: sessionController,
                expensesRepository: expensesRepository,
                financialAssistantRepository: financialAssistantRepository,
                householdMembersRepository: householdMembersRepository,
                reportsRepository: reportsRepository,
                reviewOperationsRepository: reviewOperationsRepository,
              );
            },
          ),
        ],
      ),
    ],
  );
}

class _AuthenticatedShell extends StatelessWidget {
  const _AuthenticatedShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF7F8F7)),
      child: child,
    );
  }
}
