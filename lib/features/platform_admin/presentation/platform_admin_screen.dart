import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _householdNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  PlatformAdminHousehold? _lastProvisioned;

  @override
  void dispose() {
    _householdNameController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
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
      _formKey.currentState?.reset();
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
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
          ],
        ),
      ),
    );
  }
}
