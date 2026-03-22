import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/material.dart';

class DespesasApp extends StatefulWidget {
  const DespesasApp({
    super.key,
    required this.environment,
    required this.sessionController,
    required this.expensesRepository,
    required this.financialAssistantRepository,
    required this.householdMembersRepository,
    required this.platformAdminRepository,
    required this.reportsRepository,
    required this.reviewOperationsRepository,
    this.autoRestoreSession = true,
  });

  final AppEnvironment environment;
  final SessionController sessionController;
  final ExpensesRepository expensesRepository;
  final FinancialAssistantRepository financialAssistantRepository;
  final HouseholdMembersRepository householdMembersRepository;
  final PlatformAdminRepository platformAdminRepository;
  final ReportsRepository reportsRepository;
  final ReviewOperationsRepository reviewOperationsRepository;
  final bool autoRestoreSession;

  @override
  State<DespesasApp> createState() => _DespesasAppState();
}

class _DespesasAppState extends State<DespesasApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoRestoreSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.sessionController.restoreSession();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despesas',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: ListenableBuilder(
        listenable: widget.sessionController,
        builder: (context, _) {
          switch (widget.sessionController.status) {
            case SessionStatus.bootstrapping:
              return const _SplashScreen();
            case SessionStatus.unauthenticated:
              return LoginScreen(
                sessionController: widget.sessionController,
                environment: widget.environment,
              );
            case SessionStatus.authenticated:
              if (widget.sessionController.currentUser?.role ==
                  'PLATFORM_ADMIN') {
                return PlatformAdminScreen(
                  sessionController: widget.sessionController,
                  platformAdminRepository: widget.platformAdminRepository,
                );
              }
              return ExpensesListScreen(
                sessionController: widget.sessionController,
                expensesRepository: widget.expensesRepository,
                financialAssistantRepository:
                    widget.financialAssistantRepository,
                householdMembersRepository: widget.householdMembersRepository,
                reportsRepository: widget.reportsRepository,
                reviewOperationsRepository: widget.reviewOperationsRepository,
              );
          }
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
