import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/presentation/responsive_scroll_body.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.sessionController,
    required this.token,
  });

  final SessionController sessionController;
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmationController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _newPasswordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Token ausente. Solicite um novo link.';
      });
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.sessionController.resetPassword(
        token: token,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _newPasswordConfirmationController.text,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Senha atualizada'),
          content: Text(
            result.revokedRefreshTokens > 0
                ? 'Senha redefinida com sucesso. A sessão anterior foi encerrada.'
                : 'Senha redefinida com sucesso.',
          ),
          actions: [
            FilledButton(
              key: const ValueKey('reset-password-success-close-button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ir para login'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível redefinir agora. Tente novamente.';
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
    final hasToken = widget.token != null && widget.token!.isNotEmpty;

    return AppScaffold(
      title: 'Redefinir senha',
      subtitle: 'Crie uma nova senha para voltar a acessar.',
      body: ResponsiveScrollBody(
        maxWidth: 480,
        centerVertically: true,
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nova senha', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                hasToken
                    ? 'Defina a nova senha. O token expira em poucos minutos.'
                    : 'O token não foi encontrado. Solicite um novo link.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF58616A),
                ),
              ),
              const SizedBox(height: 20),
              if (hasToken)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const ValueKey('reset-password-new-field'),
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          suffixIcon: IconButton(
                            key: const ValueKey('reset-password-new-toggle'),
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNew = !_obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a nova senha.';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('reset-password-confirm-field'),
                        controller: _newPasswordConfirmationController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Confirmação da nova senha',
                          suffixIcon: IconButton(
                            key: const ValueKey(
                              'reset-password-confirm-toggle',
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme a nova senha.';
                          }
                          if (value != _newPasswordController.text) {
                            return 'A confirmação deve ser igual à nova senha.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
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
              const SizedBox(height: 20),
              if (hasToken)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('reset-password-submit-button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Redefinir senha'),
                  ),
                )
              else
                OutlinedButton(
                  key: const ValueKey('reset-password-missing-token-button'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Solicitar novo link'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
