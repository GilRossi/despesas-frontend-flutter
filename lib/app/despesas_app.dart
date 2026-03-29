import 'package:despesas_frontend/app/app_router.dart';
import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/app/splash_screen.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DespesasApp extends StatefulWidget {
  const DespesasApp({
    super.key,
    required this.environment,
    required this.sessionController,
    required this.expensesRepository,
    required this.fixedBillsRepository,
    required this.financialAssistantRepository,
    required this.historyImportsRepository,
    required this.householdMembersRepository,
    required this.incomesRepository,
    required this.platformAdminRepository,
    required this.reportsRepository,
    required this.reviewOperationsRepository,
    required this.dashboardRepository,
    required this.spaceReferencesRepository,
    this.autoRestoreSession = true,
  });

  final AppEnvironment environment;
  final SessionController sessionController;
  final ExpensesRepository expensesRepository;
  final FixedBillsRepository fixedBillsRepository;
  final FinancialAssistantRepository financialAssistantRepository;
  final HistoryImportsRepository historyImportsRepository;
  final HouseholdMembersRepository householdMembersRepository;
  final IncomesRepository incomesRepository;
  final PlatformAdminRepository platformAdminRepository;
  final ReportsRepository reportsRepository;
  final ReviewOperationsRepository reviewOperationsRepository;
  final DashboardRepository dashboardRepository;
  final SpaceReferencesRepository spaceReferencesRepository;
  final bool autoRestoreSession;

  @override
  State<DespesasApp> createState() => _DespesasAppState();
}

class _DespesasAppState extends State<DespesasApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    if (widget.autoRestoreSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.sessionController.restoreSession();
      });
    }

    _router = createAppRouter(
      sessionController: widget.sessionController,
      expensesRepository: widget.expensesRepository,
      fixedBillsRepository: widget.fixedBillsRepository,
      financialAssistantRepository: widget.financialAssistantRepository,
      historyImportsRepository: widget.historyImportsRepository,
      householdMembersRepository: widget.householdMembersRepository,
      incomesRepository: widget.incomesRepository,
      platformAdminRepository: widget.platformAdminRepository,
      reportsRepository: widget.reportsRepository,
      reviewOperationsRepository: widget.reviewOperationsRepository,
      dashboardRepository: widget.dashboardRepository,
      spaceReferencesRepository: widget.spaceReferencesRepository,
      splashScreen: const SplashScreen(),
      loginScreenBuilder: () => LoginScreen(
        sessionController: widget.sessionController,
        environment: widget.environment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Despesas',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
