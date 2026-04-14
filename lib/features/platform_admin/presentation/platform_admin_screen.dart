import 'dart:math' as math;

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_health.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({
    super.key,
    required this.sessionController,
    required this.platformAdminRepository,
  });

  final SessionController sessionController;
  final PlatformAdminRepository platformAdminRepository;

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen> {
  final _provisionFormKey = GlobalKey<FormState>();
  final _passwordResetFormKey = GlobalKey<FormState>();
  final _spaceNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _resetTargetEmailController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetPasswordConfirmationController = TextEditingController();

  bool _isLoadingPlatformData = true;
  bool _isSubmitting = false;
  bool _isResetSubmitting = false;
  String? _platformErrorMessage;
  String? _createErrorMessage;
  String? _resetErrorMessage;
  Map<String, String> _resetFieldErrors = const {};
  PlatformAdminOverview? _overview;
  PlatformAdminHealth? _health;
  List<PlatformAdminSpace> _spaces = const [];
  PlatformAdminHousehold? _lastProvisioned;
  AdminPasswordResetResult? _lastPasswordReset;

  @override
  void initState() {
    super.initState();
    _loadPlatformData();
  }

  @override
  void dispose() {
    _spaceNameController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _resetTargetEmailController.dispose();
    _resetPasswordController.dispose();
    _resetPasswordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlatformData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoadingPlatformData = true;
        _platformErrorMessage = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        widget.platformAdminRepository.fetchOverview(),
        widget.platformAdminRepository.fetchHealth(),
        widget.platformAdminRepository.fetchSpaces(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = results[0] as PlatformAdminOverview;
        _health = results[1] as PlatformAdminHealth;
        _spaces = results[2] as List<PlatformAdminSpace>;
        _platformErrorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _platformErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _platformErrorMessage = 'Não foi possível carregar o admin agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlatformData = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final valid = _provisionFormKey.currentState?.validate() ?? false;
    if (!valid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _createErrorMessage = null;
    });

    try {
      final provisioned = await widget.platformAdminRepository
          .createHouseholdWithOwner(
            CreateHouseholdOwnerInput(
              householdName: _spaceNameController.text.trim(),
              ownerName: _ownerNameController.text.trim(),
              ownerEmail: _ownerEmailController.text.trim(),
              ownerPassword: _ownerPasswordController.text,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastProvisioned = provisioned;
      });
      _provisionFormKey.currentState?.reset();
      _spaceNameController.clear();
      _ownerNameController.clear();
      _ownerEmailController.clear();
      _ownerPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espaço criado com sucesso.')),
      );
      await _loadPlatformData(showLoading: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _createErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _createErrorMessage = 'Não foi possível criar o Espaço agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitPasswordReset() async {
    final valid = _passwordResetFormKey.currentState?.validate() ?? false;
    if (!valid || _isResetSubmitting) {
      return;
    }

    setState(() {
      _isResetSubmitting = true;
      _resetErrorMessage = null;
      _resetFieldErrors = const {};
    });

    try {
      final result = await widget.platformAdminRepository.resetUserPassword(
        AdminPasswordResetInput(
          targetEmail: _resetTargetEmailController.text.trim(),
          newPassword: _resetPasswordController.text,
          newPasswordConfirmation: _resetPasswordConfirmationController.text,
        ),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _lastPasswordReset = result;
      });
      _passwordResetFormKey.currentState?.reset();
      _resetTargetEmailController.clear();
      _resetPasswordController.clear();
      _resetPasswordConfirmationController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha resetada com sucesso.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetErrorMessage = error.message;
        _resetFieldErrors = error.fieldErrors;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetErrorMessage = 'Não foi possível resetar a senha agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetSubmitting = false;
        });
      }
    }
  }

  Future<void> _openChangePassword() async {
    try {
      context.go('/change-password');
      return;
    } catch (_) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              ChangePasswordScreen(sessionController: widget.sessionController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.sessionController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin da plataforma'),
        actions: [
          IconButton(
            key: const ValueKey('platform-admin-refresh-button'),
            tooltip: 'Atualizar',
            onPressed: _isLoadingPlatformData
                ? null
                : () => _loadPlatformData(showLoading: false),
            icon: _isLoadingPlatformData
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.sessionController.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadPlatformData(showLoading: false),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdminHeroCard(
                        adminName: admin?.name ?? 'Platform Admin',
                        onOpenChangePassword: _openChangePassword,
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingPlatformData &&
                          _overview == null &&
                          _health == null &&
                          _spaces.isEmpty)
                        const _PlatformAdminLoadingState()
                      else if (_platformErrorMessage != null &&
                          _overview == null &&
                          _health == null &&
                          _spaces.isEmpty)
                        _StateCard(
                          title: 'Não foi possível carregar o admin agora.',
                          message: _platformErrorMessage!,
                          actionLabel: 'Tentar novamente',
                          onAction: _loadPlatformData,
                        )
                      else ...[
                        if (_platformErrorMessage != null) ...[
                          _InlineMessageCard(
                            title: 'Falha ao atualizar a visão do admin',
                            message: _platformErrorMessage!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_overview != null) ...[
                          _OverviewSection(overview: _overview!),
                          const SizedBox(height: 16),
                        ],
                        if (_health != null) ...[
                          _HealthSection(health: _health!),
                          const SizedBox(height: 16),
                        ],
                        _SpacesSection(spaces: _spaces),
                        const SizedBox(height: 16),
                      ],
                      _CreateSpaceSection(
                        formKey: _provisionFormKey,
                        spaceNameController: _spaceNameController,
                        ownerNameController: _ownerNameController,
                        ownerEmailController: _ownerEmailController,
                        ownerPasswordController: _ownerPasswordController,
                        errorMessage: _createErrorMessage,
                        isSubmitting: _isSubmitting,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 16),
                      _PasswordResetSection(
                        formKey: _passwordResetFormKey,
                        targetEmailController: _resetTargetEmailController,
                        newPasswordController: _resetPasswordController,
                        confirmationController:
                            _resetPasswordConfirmationController,
                        errorMessage: _resetErrorMessage,
                        fieldErrors: _resetFieldErrors,
                        isSubmitting: _isResetSubmitting,
                        onSubmit: _submitPasswordReset,
                      ),
                      if (_lastProvisioned != null) ...[
                        const SizedBox(height: 16),
                        _LastProvisionedCard(
                          lastProvisioned: _lastProvisioned!,
                        ),
                      ],
                      if (_lastPasswordReset != null) ...[
                        const SizedBox(height: 16),
                        _LastPasswordResetCard(
                          lastPasswordReset: _lastPasswordReset!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.adminName,
    required this.onOpenChangePassword,
  });

  final String adminName;
  final Future<void> Function() onOpenChangePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adminName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe a plataforma, veja os Espaços ativos e confira a saúde básica do sistema.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65727B),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            key: const ValueKey('platform-admin-open-change-password-button'),
            onPressed: onOpenChangePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Minha senha'),
          ),
        ],
      ),
    );
  }
}

class _PlatformAdminLoadingState extends StatelessWidget {
  const _PlatformAdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.overview});

  final PlatformAdminOverview overview;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-overview-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão geral',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Leitura rápida da plataforma com os dados disponíveis nesta primeira fase.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.max(
                180.0,
                math.min(230.0, (constraints.maxWidth - 16) / 2),
              );
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricCard(
                    label: 'Espaços',
                    value: overview.totalSpaces.toString(),
                    helper: '${overview.activeSpaces} ativos',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Usuários',
                    value: overview.totalUsers.toString(),
                    helper: 'Cadastros ativos',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Admins da plataforma',
                    value: overview.totalPlatformAdmins.toString(),
                    helper: 'Acessos administrativos',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Actuator',
                    value: overview.actuator.healthExposed
                        ? 'Health exposto'
                        : 'Health fechado',
                    helper: overview.actuator.metricsExposed
                        ? 'Metrics expostas'
                        : 'Metrics não expostas',
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: overview.modules
                .map((module) => _ModuleUsageChip(module: module))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.health});

  final PlatformAdminHealth health;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-health-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saúde do sistema',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Status atual do backend, do runtime e das exposições públicas do Actuator.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.max(
                200.0,
                math.min(250.0, (constraints.maxWidth - 16) / 2),
              );
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricCard(
                    label: 'Status geral',
                    value: health.applicationStatus,
                    helper: _formatDateTime(health.checkedAt),
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Processadores',
                    value: health.jvm.availableProcessors.toString(),
                    helper: 'Disponíveis no runtime',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Uptime',
                    value: _formatUptime(health.jvm.uptimeMs),
                    helper: 'Tempo desde a subida',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Load médio',
                    value: health.system.systemLoadAverage == null
                        ? 'Indisponível'
                        : _formatDecimal(
                            health.system.systemLoadAverage!,
                            fractionDigits: 2,
                          ),
                    helper: 'Leitura atual do host',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Heap usado',
                    value: _formatBytes(health.jvm.heapUsedBytes),
                    helper: 'Em uso agora',
                    width: cardWidth,
                  ),
                  _MetricCard(
                    label: 'Heap reservado',
                    value: _formatBytes(health.jvm.heapCommittedBytes),
                    helper: 'Reservado pela JVM',
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatusChip(
                label: health.actuator.healthExposed
                    ? 'Actuator health exposto'
                    : 'Actuator health fechado',
                positive: health.actuator.healthExposed,
              ),
              _StatusChip(
                label: health.actuator.infoExposed
                    ? 'Actuator info exposto'
                    : 'Actuator info fechado',
                positive: health.actuator.infoExposed,
              ),
              _StatusChip(
                label: health.actuator.metricsExposed
                    ? 'Actuator metrics exposto'
                    : 'Actuator metrics fechado',
                positive: health.actuator.metricsExposed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            health.actuator.metricsExposed
                ? 'Métricas HTTP já expostas nesta fase.'
                : 'Métricas HTTP ainda não expostas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (health.info.isEmpty)
            const _InlineMessageCard(
              title: 'Info do runtime',
              message: 'Sem informações extras publicadas agora.',
            )
          else
            _InfoMapCard(info: health.info),
        ],
      ),
    );
  }
}

class _SpacesSection extends StatelessWidget {
  const _SpacesSection({required this.spaces});

  final List<PlatformAdminSpace> spaces;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-spaces-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Espaços',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Lista atual dos Espaços disponíveis com responsável, membros e módulos habilitados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (spaces.isEmpty)
            const _InlineMessageCard(
              title: 'Nenhum Espaço cadastrado.',
              message:
                  'Crie o primeiro Espaço para começar a administrar a plataforma.',
            )
          else
            Column(
              children: [
                for (var index = 0; index < spaces.length; index++) ...[
                  _SpaceCard(space: spaces[index]),
                  if (index < spaces.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CreateSpaceSection extends StatelessWidget {
  const _CreateSpaceSection({
    required this.formKey,
    required this.spaceNameController,
    required this.ownerNameController,
    required this.ownerEmailController,
    required this.ownerPasswordController,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController spaceNameController;
  final TextEditingController ownerNameController;
  final TextEditingController ownerEmailController;
  final TextEditingController ownerPasswordController;
  final String? errorMessage;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar Espaço',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre um novo Espaço com o primeiro responsável já pronto para acessar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('platform-admin-household-name-field'),
              controller: spaceNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome do Espaço'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do Espaço.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('platform-admin-owner-name-field'),
              controller: ownerNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome do responsável',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do responsável.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('platform-admin-owner-email-field'),
              controller: ownerEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail do responsável',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty || !trimmed.contains('@')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('platform-admin-owner-password-field'),
              controller: ownerPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Senha inicial do responsável',
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'A senha deve ter ao menos 6 caracteres.';
                }
                return null;
              },
              onFieldSubmitted: (_) => onSubmit(),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('platform-admin-submit-button'),
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_business_outlined),
              label: Text(isSubmitting ? 'Criando Espaço...' : 'Criar Espaço'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordResetSection extends StatelessWidget {
  const _PasswordResetSection({
    required this.formKey,
    required this.targetEmailController,
    required this.newPasswordController,
    required this.confirmationController,
    required this.errorMessage,
    required this.fieldErrors,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController targetEmailController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmationController;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset administrativo de senha',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use quando alguém perder o acesso e precisar receber uma nova senha temporária.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('platform-admin-reset-target-email-field'),
              controller: targetEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'E-mail da conta',
                errorText: fieldErrors['targetEmail'],
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty || !trimmed.contains('@')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('platform-admin-reset-new-password-field'),
              controller: newPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nova senha temporária',
                errorText: fieldErrors['newPassword'],
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'A senha deve ter ao menos 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey(
                'platform-admin-reset-confirm-password-field',
              ),
              controller: confirmationController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Confirmação da nova senha',
                errorText: fieldErrors['newPasswordConfirmation'],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme a nova senha.';
                }
                if (value != newPasswordController.text) {
                  return 'A confirmação deve ser igual à nova senha.';
                }
                return null;
              },
              onFieldSubmitted: (_) => onSubmit(),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('platform-admin-reset-submit-button'),
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_outlined),
              label: Text(
                isSubmitting ? 'Resetando senha...' : 'Resetar senha',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastProvisionedCard extends StatelessWidget {
  const _LastProvisionedCard({required this.lastProvisioned});

  final PlatformAdminHousehold lastProvisioned;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-last-provisioned-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último Espaço criado',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text('Espaço: ${lastProvisioned.householdName}'),
          const SizedBox(height: 4),
          Text('Responsável: ${lastProvisioned.ownerEmail}'),
          const SizedBox(height: 4),
          Text('Perfil: ${lastProvisioned.ownerRole}'),
        ],
      ),
    );
  }
}

class _LastPasswordResetCard extends StatelessWidget {
  const _LastPasswordResetCard({required this.lastPasswordReset});

  final AdminPasswordResetResult lastPasswordReset;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-last-reset-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último reset de senha',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text('Conta: ${lastPasswordReset.targetEmailMasked}'),
          const SizedBox(height: 4),
          Text(
            'Refresh tokens revogados: ${lastPasswordReset.revokedRefreshTokens}',
          ),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.space});

  final PlatformAdminSpace space;

  @override
  Widget build(BuildContext context) {
    final owner = space.owner;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  space.spaceName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _StatusChip(
                  label: _spaceStatusLabel(space),
                  positive: owner != null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID do Espaço: ${space.spaceId}'),
            const SizedBox(height: 4),
            Text(
              owner == null
                  ? 'Responsável: não definido.'
                  : 'Responsável: ${owner.name} · ${owner.email}',
            ),
            const SizedBox(height: 4),
            Text('Membros ativos: ${space.activeMembersCount}'),
            const SizedBox(height: 4),
            Text('Criado em: ${_formatDateTime(space.createdAt)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: space.modules
                  .map((module) => Chip(label: Text(_spaceModuleLabel(module))))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.width,
  });

  final String label;
  final String value;
  final String helper;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                helper,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF65727B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleUsageChip extends StatelessWidget {
  const _ModuleUsageChip({required this.module});

  final PlatformAdminModuleUsage module;

  @override
  Widget build(BuildContext context) {
    final label =
        '${_moduleLabel(module.key)}: ${module.enabledSpaces} ligados · ${module.disabledSpaces} desligados';
    final suffix = module.mandatory ? ' · obrigatório' : '';

    return Chip(label: Text('$label$suffix'));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = positive
        ? const (background: Color(0xFFE2F6EA), foreground: Color(0xFF0F6B3A))
        : const (background: Color(0xFFFDEBEB), foreground: Color(0xFFAA2E2E));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoMapCard extends StatelessWidget {
  const _InfoMapCard({required this.info});

  final Map<String, dynamic> info;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Info do runtime',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final entry in info.entries) ...[
              Text('${entry.key}: ${entry.value}'),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

String _spaceStatusLabel(PlatformAdminSpace space) {
  if (space.owner == null) {
    return 'Sem responsável';
  }
  if (space.activeMembersCount <= 0) {
    return 'Sem membros';
  }
  return 'Ativo';
}

String _spaceModuleLabel(PlatformAdminSpaceModule module) {
  final base = _moduleLabel(module.key);
  if (module.mandatory) {
    return '$base obrigatório';
  }
  return module.enabled ? '$base ligado' : '$base desligado';
}

String _moduleLabel(String key) {
  return switch (key) {
    'FINANCIAL' => 'Financeiro',
    'DRIVER' => 'Motorista',
    _ => key,
  };
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final decimals = value >= 100 || unitIndex == 0 ? 0 : 1;
  return '${_formatDecimal(value, fractionDigits: decimals)} ${units[unitIndex]}';
}

String _formatDecimal(double value, {int fractionDigits = 2}) {
  return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Indisponível';
  }
  final local = value.toLocal();
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String _formatUptime(int uptimeMs) {
  if (uptimeMs <= 0) {
    return '0 min';
  }

  final totalSeconds = uptimeMs ~/ 1000;
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;

  if (days > 0) {
    return '${days}d ${hours}h';
  }
  if (hours > 0) {
    return '${hours}h ${minutes}min';
  }
  return '${math.max(1, minutes)} min';
}
