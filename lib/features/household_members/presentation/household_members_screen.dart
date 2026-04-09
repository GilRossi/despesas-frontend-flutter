import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_shell_scaffold.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/household_members/presentation/household_members_view_model.dart';
import 'package:flutter/material.dart';

class HouseholdMembersScreen extends StatefulWidget {
  const HouseholdMembersScreen({
    super.key,
    required this.householdMembersRepository,
    required this.sessionController,
  });

  final HouseholdMembersRepository householdMembersRepository;
  final SessionController sessionController;

  @override
  State<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends State<HouseholdMembersScreen> {
  late final HouseholdMembersViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HouseholdMembersViewModel(
      householdMembersRepository: widget.householdMembersRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final created = await _viewModel.createMember(
      CreateHouseholdMemberInput(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );

    if (!mounted || !created) {
      return;
    }

    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Membro criado. O novo login já pode usar a tela oficial.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AuthenticatedShellScaffold(
          sessionController: widget.sessionController,
          currentLocation: '/household-members',
          title: 'Membros do espaço',
          fallbackRoute: '/',
          body: RefreshIndicator(
            onRefresh: _viewModel.load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fluxo mínimo multiusuário',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'O responsável pode adicionar um novo login ao espaço atual. A nova pessoa entra pela mesma tela de login do produto.',
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
                            'Adicionar membro',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('household-member-name-field'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              errorText: _viewModel.fieldError('name'),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o nome.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('household-member-email-field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              errorText: _viewModel.fieldError('email'),
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
                            key: const ValueKey(
                              'household-member-password-field',
                            ),
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Senha inicial',
                              errorText: _viewModel.fieldError('password'),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'A senha deve ter ao menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                          if (_viewModel.submitErrorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.submitErrorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const ValueKey(
                              'household-member-submit-button',
                            ),
                            onPressed: _viewModel.isSubmitting ? null : _submit,
                            icon: _viewModel.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1),
                            label: Text(
                              _viewModel.isSubmitting
                                  ? 'Adicionando...'
                                  : 'Adicionar membro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_viewModel.isLoading) ...[
                  const SizedBox(height: 120),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_viewModel.loadErrorMessage != null) ...[
                  _StateCard(
                    title: _viewModel.isForbidden
                        ? 'Acesso restrito aos responsáveis'
                        : _viewModel.isUnauthorized
                        ? 'Sessão expirada'
                        : 'Não foi possível carregar os membros.',
                    message: _viewModel.loadErrorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _viewModel.load,
                  ),
                ] else if (_viewModel.isEmpty) ...[
                  const _StateCard(
                    title: 'Nenhum membro encontrado',
                    message:
                        'O espaço atual ainda não possui membros listados.',
                  ),
                ] else ...[
                  Text('Membros atuais', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  for (final member in _viewModel.members) ...[
                    _HouseholdMemberCard(member: member),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HouseholdMemberCard extends StatelessWidget {
  const _HouseholdMemberCard({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final memberInfo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  member.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65727B),
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  memberInfo,
                  const SizedBox(height: 12),
                  Chip(label: Text(_formatRoleLabel(member.role))),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: memberInfo),
                const SizedBox(width: 12),
                Chip(label: Text(_formatRoleLabel(member.role))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatRoleLabel(String role) {
  switch (role) {
    case 'OWNER':
      return 'Responsável';
    case 'MEMBER':
      return 'Convidado';
    default:
      return role;
  }
}
