import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:despesas_frontend/features/auth/presentation/reset_password_screen.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_screen.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:despesas_frontend/features/space_references/presentation/space_references_screen.dart';
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
  required DashboardRepository dashboardRepository,
  required SpaceReferencesRepository spaceReferencesRepository,
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
      final inForgot = state.matchedLocation == '/forgot-password';
      final inReset = state.matchedLocation == '/reset-password';
      final inAssistant = state.matchedLocation == '/assistant';
      final inSpaceReferences = state.matchedLocation == '/space/references';

      if (status == SessionStatus.bootstrapping) {
        return inSplash ? null : '/splash';
      }

      if (status == SessionStatus.unauthenticated) {
        if (loggingIn || inForgot || inReset) {
          return null;
        }
        return '/login';
      }

      // Authenticated
      if (sessionController.requiresOnboarding) {
        return inAssistant || inSpaceReferences ? null : '/assistant';
      }

      if (loggingIn || inSplash || inForgot || inReset) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => splashScreen),
      GoRoute(
        path: '/login',
        builder: (context, state) => loginScreenBuilder(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordScreen(sessionController: sessionController),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          sessionController: sessionController,
          token: state.uri.queryParameters['token'],
        ),
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

              return DashboardScreen(
                dashboardRepository: dashboardRepository,
                sessionController: sessionController,
              );
            },
          ),
          GoRoute(
            path: '/assistant',
            builder: (context, state) => FinancialAssistantScreen(
              financialAssistantRepository: financialAssistantRepository,
              sessionController: sessionController,
              onStarterPrimaryActionRequested: (primaryActionKey) {
                if (primaryActionKey == 'OPEN_CONFIGURE_SPACE') {
                  context.go('/space/references');
                }
              },
            ),
          ),
          GoRoute(
            path: '/space/references',
            builder: (context, state) => SpaceReferencesScreen(
              spaceReferencesRepository: spaceReferencesRepository,
            ),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => ExpensesListScreen(
              sessionController: sessionController,
              expensesRepository: expensesRepository,
              financialAssistantRepository: financialAssistantRepository,
              householdMembersRepository: householdMembersRepository,
              reportsRepository: reportsRepository,
              reviewOperationsRepository: reviewOperationsRepository,
            ),
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
