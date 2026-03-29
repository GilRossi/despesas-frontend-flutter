import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:despesas_frontend/features/auth/presentation/reset_password_screen.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_payment_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/presentation/financial_assistant_screen.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';
import 'package:despesas_frontend/features/history_imports/presentation/history_import_form_screen.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/household_members/presentation/household_members_screen.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';
import 'package:despesas_frontend/features/incomes/presentation/income_form_screen.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/presentation/reports_screen.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operation_detail_screen.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_screen.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:despesas_frontend/features/space_references/presentation/space_references_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter({
  required SessionController sessionController,
  required ExpensesRepository expensesRepository,
  required FixedBillsRepository fixedBillsRepository,
  required FinancialAssistantRepository financialAssistantRepository,
  required HistoryImportsRepository historyImportsRepository,
  required HouseholdMembersRepository householdMembersRepository,
  required IncomesRepository incomesRepository,
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
      final inFixedBillsNew = state.matchedLocation == '/fixed-bills/new';
      final inHistoryImport = state.matchedLocation == '/history/import';
      final inIncomeNew = state.matchedLocation == '/incomes/new';
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
        return inAssistant ||
                inFixedBillsNew ||
                inHistoryImport ||
                inIncomeNew ||
                inSpaceReferences
            ? null
            : '/assistant';
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
                if (primaryActionKey == 'OPEN_IMPORT_HISTORY') {
                  context.go('/history/import');
                }
                if (primaryActionKey == 'OPEN_FIXED_BILLS') {
                  context.go('/fixed-bills/new');
                }
                if (primaryActionKey == 'OPEN_REGISTER_INCOME') {
                  context.go('/incomes/new');
                }
                if (primaryActionKey == 'OPEN_CONFIGURE_SPACE') {
                  context.go('/space/references');
                }
              },
            ),
          ),
          GoRoute(
            path: '/household-members',
            builder: (context, state) => HouseholdMembersScreen(
              householdMembersRepository: householdMembersRepository,
            ),
          ),
          GoRoute(
            path: '/change-password',
            builder: (context, state) =>
                ChangePasswordScreen(sessionController: sessionController),
          ),
          GoRoute(
            path: '/history/import',
            builder: (context, state) => HistoryImportFormScreen(
              historyImportsRepository: historyImportsRepository,
              expensesRepository: expensesRepository,
            ),
          ),
          GoRoute(
            path: '/fixed-bills/new',
            builder: (context, state) => FixedBillFormScreen(
              fixedBillsRepository: fixedBillsRepository,
              expensesRepository: expensesRepository,
              spaceReferencesRepository: spaceReferencesRepository,
            ),
          ),
          GoRoute(
            path: '/incomes/new',
            builder: (context, state) => IncomeFormScreen(
              incomesRepository: incomesRepository,
              spaceReferencesRepository: spaceReferencesRepository,
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
          GoRoute(
            path: '/expenses/new',
            builder: (context, state) => ExpenseFormScreen(
              expensesRepository: expensesRepository,
              standalone: true,
            ),
          ),
          GoRoute(
            path: '/expenses/:expenseId/pay',
            builder: (context, state) {
              final expenseId = int.tryParse(
                state.pathParameters['expenseId'] ?? '',
              );
              if (expenseId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Nao foi possivel abrir este pagamento.'),
                  ),
                );
              }
              return ExpensePaymentScreen(
                expenseId: expenseId,
                expensesRepository: expensesRepository,
              );
            },
          ),
          GoRoute(
            path: '/expenses/:expenseId',
            builder: (context, state) {
              final expenseId = int.tryParse(
                state.pathParameters['expenseId'] ?? '',
              );
              if (expenseId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Nao foi possivel abrir esta despesa.'),
                  ),
                );
              }

              return ExpenseDetailScreen(
                expenseId: expenseId,
                expensesRepository: expensesRepository,
              );
            },
          ),
          GoRoute(
            path: '/review-operations',
            builder: (context, state) => ReviewOperationsListScreen(
              reviewOperationsRepository: reviewOperationsRepository,
            ),
          ),
          GoRoute(
            path: '/review-operations/:ingestionId',
            builder: (context, state) {
              final ingestionId = int.tryParse(
                state.pathParameters['ingestionId'] ?? '',
              );
              if (ingestionId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Nao foi possivel abrir esta review.'),
                  ),
                );
              }

              return ReviewOperationDetailScreen(
                ingestionId: ingestionId,
                reviewOperationsRepository: reviewOperationsRepository,
              );
            },
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) =>
                ReportsScreen(reportsRepository: reportsRepository),
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
