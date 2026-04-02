import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.sessionController,
    required this.environment,
  });

  final SessionController sessionController;
  final AppEnvironment environment;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    await widget.sessionController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Entrar',
      subtitle: 'Acesse seu Espaço de gestão financeira',
      body: ResponsiveScrollBody(
        maxWidth: 480,
        centerVertically: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: SectionCard(
          child: ListenableBuilder(
            listenable: widget.sessionController,
            builder: (context, _) {
              final isSubmitting = widget.sessionController.isSubmitting;
              final errorMessage = widget.sessionController.errorMessage;

              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Entrar', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Use sua conta para acessar as despesas do seu espaço.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF58616A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('login-email-field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu e-mail.';
                        }
                        if (!value.contains('@')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('login-password-field'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe sua senha.';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('login-submit-button'),
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey('login-forgot-password-button'),
                        onPressed: isSubmitting
                            ? null
                            : () => context.go('/forgot-password'),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ambiente: ${widget.environment.name} · ${widget.environment.apiBaseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7A858D),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
