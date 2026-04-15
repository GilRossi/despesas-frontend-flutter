import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlatformAdminSpaceDetailScreen extends StatefulWidget {
  const PlatformAdminSpaceDetailScreen({
    super.key,
    required this.spaceId,
    required this.sessionController,
    required this.platformAdminRepository,
  });

  final int spaceId;
  final SessionController sessionController;
  final PlatformAdminRepository platformAdminRepository;

  @override
  State<PlatformAdminSpaceDetailScreen> createState() =>
      _PlatformAdminSpaceDetailScreenState();
}

class _PlatformAdminSpaceDetailScreenState
    extends State<PlatformAdminSpaceDetailScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _saveErrorMessage;
  PlatformAdminSpace? _space;
  bool _driverEnabled = false;

  bool get _hasDirtyModules {
    final driverModule = _driverModule;
    if (driverModule == null) {
      return false;
    }
    return driverModule.enabled != _driverEnabled;
  }

  PlatformAdminSpaceModule? get _driverModule {
    final space = _space;
    if (space == null) {
      return null;
    }
    for (final module in space.modules) {
      if (module.key == 'DRIVER') {
        return module;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSpace();
  }

  Future<void> _loadSpace({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
      });
    }

    try {
      final space = await widget.platformAdminRepository.fetchSpace(
        widget.spaceId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _space = space;
        _driverEnabled = space.modules
            .firstWhere(
              (module) => module.key == 'DRIVER',
              orElse: () => const PlatformAdminSpaceModule(
                key: 'DRIVER',
                enabled: false,
                mandatory: false,
              ),
            )
            .enabled;
        _loadErrorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadErrorMessage =
            'Não foi possível carregar o detalhe do Espaço agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveModules() async {
    final space = _space;
    if (space == null || _isSaving || !_hasDirtyModules) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      final updated = await widget.platformAdminRepository.updateSpaceModules(
        spaceId: space.spaceId,
        enabledModuleKeys: _buildEnabledModuleKeys(space),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _space = updated;
        _driverEnabled = updated.modules
            .firstWhere(
              (module) => module.key == 'DRIVER',
              orElse: () => const PlatformAdminSpaceModule(
                key: 'DRIVER',
                enabled: false,
                mandatory: false,
              ),
            )
            .enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Módulos do Espaço atualizados.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorMessage =
            'Não foi possível atualizar os módulos do Espaço agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<String> _buildEnabledModuleKeys(PlatformAdminSpace space) {
    return [
      for (final module in space.modules)
        if (module.mandatory)
          module.key
        else if (module.key == 'DRIVER')
          if (_driverEnabled) module.key else if (module.enabled) module.key,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do Espaço'),
        actions: [
          IconButton(
            key: const ValueKey('platform-admin-space-detail-refresh-button'),
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : () => _loadSpace(showLoading: false),
            icon: _isLoading
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
          onRefresh: () => _loadSpace(showLoading: false),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailHeaderCard(
                        spaceName: _space?.spaceName,
                        onBack: () => context.go('/'),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading && _space == null)
                        const _LoadingState()
                      else if (_loadErrorMessage != null && _space == null)
                        _StateCard(
                          title: 'Não foi possível carregar este Espaço.',
                          message: _loadErrorMessage!,
                          actionLabel: 'Tentar novamente',
                          onAction: _loadSpace,
                        )
                      else if (_space != null) ...[
                        if (_loadErrorMessage != null) ...[
                          _InlineMessageCard(
                            title: 'Falha ao atualizar o detalhe do Espaço',
                            message: _loadErrorMessage!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SpaceSummarySection(space: _space!),
                        const SizedBox(height: 16),
                        _SpaceModulesSection(
                          space: _space!,
                          driverEnabled: _driverEnabled,
                          isSaving: _isSaving,
                          saveErrorMessage: _saveErrorMessage,
                          onDriverChanged: (value) {
                            setState(() {
                              _driverEnabled = value;
                              _saveErrorMessage = null;
                            });
                          },
                          onSave: _saveModules,
                          hasDirtyModules: _hasDirtyModules,
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

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({required this.spaceName, required this.onBack});

  final String? spaceName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spaceName ?? 'Espaço', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe os dados principais do Espaço e ajuste os módulos desta fase do admin.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65727B),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            key: const ValueKey('platform-admin-space-detail-back-button'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar para Espaços'),
          ),
        ],
      ),
    );
  }
}

class _SpaceSummarySection extends StatelessWidget {
  const _SpaceSummarySection({required this.space});

  final PlatformAdminSpace space;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('platform-admin-space-detail-summary-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Espaço',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Dados reais disponíveis nesta fase para identificar e acompanhar este Espaço.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SummaryItem(label: 'Nome', value: space.spaceName),
              _SummaryItem(
                label: 'ID do Espaço',
                value: space.spaceId.toString(),
              ),
              _SummaryItem(label: 'Status', value: _spaceStatusLabel(space)),
              _SummaryItem(
                label: 'Membros ativos',
                value: space.activeMembersCount.toString(),
              ),
              _SummaryItem(
                label: 'Criado em',
                value: _formatDateTime(space.createdAt),
              ),
              _SummaryItem(
                label: 'Atualizado em',
                value: _formatDateTime(space.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            space.owner == null
                ? 'Responsável ainda não definido.'
                : 'Responsável: ${space.owner!.name} · ${space.owner!.email}',
          ),
        ],
      ),
    );
  }
}

class _SpaceModulesSection extends StatelessWidget {
  const _SpaceModulesSection({
    required this.space,
    required this.driverEnabled,
    required this.isSaving,
    required this.saveErrorMessage,
    required this.onDriverChanged,
    required this.onSave,
    required this.hasDirtyModules,
  });

  final PlatformAdminSpace space;
  final bool driverEnabled;
  final bool isSaving;
  final String? saveErrorMessage;
  final ValueChanged<bool> onDriverChanged;
  final VoidCallback onSave;
  final bool hasDirtyModules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      key: const ValueKey('platform-admin-space-detail-modules-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Módulos do Espaço',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Edite apenas o que já está disponível nesta fase do admin.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final module in space.modules) ...[
            _ModuleTile(
              module: module,
              value: module.key == 'DRIVER' ? driverEnabled : module.enabled,
              onChanged: module.key == 'DRIVER' ? onDriverChanged : null,
            ),
            if (module != space.modules.last) const SizedBox(height: 12),
          ],
          if (saveErrorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              saveErrorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('platform-admin-space-detail-save-button'),
            onPressed: isSaving || !hasDirtyModules ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              isSaving ? 'Salvando módulos...' : 'Salvar módulos do Espaço',
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.value,
    this.onChanged,
  });

  final PlatformAdminSpaceModule module;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = module.mandatory
        ? 'Obrigatório para o funcionamento base da plataforma.'
        : 'Ative ou desligue conforme a governança do Espaço.';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _moduleLabel(module.key),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: module.mandatory
                            ? 'Obrigatório'
                            : (value ? 'Ligado' : 'Desligado'),
                        positive: value,
                      ),
                      if (!module.mandatory)
                        _StatusChip(label: 'Opcional', positive: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              key: ValueKey(
                'platform-admin-space-detail-module-switch-${module.key}',
              ),
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = positive
        ? const (background: Color(0xFFE2F6EA), foreground: Color(0xFF0F6B3A))
        : const (background: Color(0xFFF3F5F7), foreground: Color(0xFF56636D));

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

String _spaceStatusLabel(PlatformAdminSpace space) {
  if (space.owner == null) {
    return 'Sem responsável';
  }
  if (space.activeMembersCount <= 0) {
    return 'Sem membros';
  }
  return 'Ativo';
}

String _moduleLabel(String key) {
  return switch (key) {
    'FINANCIAL' => 'Financeiro',
    'DRIVER' => 'Motorista',
    _ => key,
  };
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Indisponível';
  }
  final local = value.toLocal();
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
