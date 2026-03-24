import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:flutter/material.dart';

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
  final _householdNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _resetTargetEmailController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetPasswordConfirmationController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResetSubmitting = false;
  String? _errorMessage;
  String? _resetErrorMessage;
  Map<String, String> _resetFieldErrors = const {};
  PlatformAdminHousehold? _lastProvisioned;
  AdminPasswordResetResult? _lastPasswordReset;

  @override
  void dispose() {
    _householdNameController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _resetTargetEmailController.dispose();
    _resetPasswordController.dispose();
    _resetPasswordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _provisionFormKey.currentState?.validate() ?? false;
    if (!valid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final provisioned = await widget.platformAdminRepository
          .createHouseholdWithOwner(
            CreateHouseholdOwnerInput(
              householdName: _householdNameController.text.trim(),
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
      _householdNameController.clear();
      _ownerNameController.clear();
      _ownerEmailController.clear();
      _ownerPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household e owner criados com sucesso.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Nao foi possivel provisionar o household agora.';
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
        _resetErrorMessage = 'Nao foi possivel resetar a senha agora.';
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ChangePasswordScreen(sessionController: widget.sessionController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = widget.sessionController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provisionamento administrativo'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.sessionController.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin?.name ?? 'Platform Admin',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie um household e o primeiro owner sem abrir cadastro publico.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF65727B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey(
                        'platform-admin-open-change-password-button',
                      ),
                      onPressed: _openChangePassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Minha senha'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _provisionFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar household + owner',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey(
                          'platform-admin-household-name-field',
                        ),
                        controller: _householdNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome do household',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome do household.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('platform-admin-owner-name-field'),
                        controller: _ownerNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome do owner',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome do owner.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('platform-admin-owner-email-field'),
                        controller: _ownerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email do owner',
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty || !trimmed.contains('@')) {
                            return 'Informe um email valido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey(
                          'platform-admin-owner-password-field',
                        ),
                        controller: _ownerPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Senha inicial do owner',
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'A senha deve ter ao menos 6 caracteres.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('platform-admin-submit-button'),
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.admin_panel_settings_outlined),
                        label: Text(
                          _isSubmitting
                              ? 'Provisionando...'
                              : 'Criar household + owner',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _passwordResetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset administrativo de senha',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fluxo restrito a PLATFORM_ADMIN. Informe o e-mail do usuario alvo e a nova senha. Outros platform admins devem usar apenas o proprio fluxo autenticado.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF65727B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey(
                          'platform-admin-reset-target-email-field',
                        ),
                        controller: _resetTargetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email do usuario alvo',
                          errorText: _resetFieldErrors['targetEmail'],
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty || !trimmed.contains('@')) {
                            return 'Informe um email valido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey(
                          'platform-admin-reset-new-password-field',
                        ),
                        controller: _resetPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nova senha provisoria',
                          errorText: _resetFieldErrors['newPassword'],
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
                        controller: _resetPasswordConfirmationController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirmacao da nova senha',
                          errorText:
                              _resetFieldErrors['newPasswordConfirmation'],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme a nova senha.';
                          }
                          if (value != _resetPasswordController.text) {
                            return 'A confirmacao deve ser igual a nova senha.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submitPasswordReset(),
                      ),
                      if (_resetErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _resetErrorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey(
                          'platform-admin-reset-submit-button',
                        ),
                        onPressed: _isResetSubmitting
                            ? null
                            : _submitPasswordReset,
                        icon: _isResetSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_reset_outlined),
                        label: Text(
                          _isResetSubmitting
                              ? 'Resetando senha...'
                              : 'Resetar senha do usuario',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_lastProvisioned != null) ...[
              const SizedBox(height: 16),
              Card(
                key: const ValueKey('platform-admin-last-provisioned-card'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ultimo provisionamento',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('Household: ${_lastProvisioned!.householdName}'),
                      const SizedBox(height: 4),
                      Text('Owner: ${_lastProvisioned!.ownerEmail}'),
                      const SizedBox(height: 4),
                      Text('Role: ${_lastProvisioned!.ownerRole}'),
                    ],
                  ),
                ),
              ),
            ],
            if (_lastPasswordReset != null) ...[
              const SizedBox(height: 16),
              Card(
                key: const ValueKey('platform-admin-last-reset-card'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ultimo reset de senha',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('Alvo: ${_lastPasswordReset!.targetEmailMasked}'),
                      const SizedBox(height: 4),
                      Text(
                        'Refresh tokens revogados: ${_lastPasswordReset!.revokedRefreshTokens}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
