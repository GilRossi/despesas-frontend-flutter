import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_bootstrap.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_repository.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
import 'package:despesas_frontend/features/driver_module/presentation/driver_module_controller.dart';
import 'package:flutter/material.dart';

class DriverModuleScreen extends StatefulWidget {
  const DriverModuleScreen({
    super.key,
    required this.sessionController,
    required this.driverModuleRepository,
    required this.driverNativeBridge,
  });

  final SessionController sessionController;
  final DriverModuleRepository driverModuleRepository;
  final DriverNativeBridge driverNativeBridge;

  @override
  State<DriverModuleScreen> createState() => _DriverModuleScreenState();
}

class _DriverModuleScreenState extends State<DriverModuleScreen>
    with WidgetsBindingObserver {
  late final DriverModuleController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DriverModuleController(
      sessionController: widget.sessionController,
      driverModuleRepository: widget.driverModuleRepository,
      driverNativeBridge: widget.driverNativeBridge,
    )..load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Module'),
            actions: [
              IconButton(
                key: const ValueKey('driver-module-refresh-button'),
                onPressed: _controller.load,
                tooltip: 'Atualizar status',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DriverModuleState state) {
    switch (state.kind) {
      case DriverModuleStateKind.loading:
        return const Center(child: CircularProgressIndicator());
      case DriverModuleStateKind.sessionUnavailable:
        return _MessageState(
          title: 'Driver Module indisponível',
          message:
              state.message ??
              'Esta camada do módulo só pode ser usada por um usuário com Espaço ativo.',
          onRetry: _controller.load,
        );
      case DriverModuleStateKind.backendBlocked:
        return _MessageState(
          title: 'Driver Module indisponível',
          message:
              state.message ??
              'O módulo Motorista não está habilitado neste Espaço.',
          onRetry: _controller.load,
        );
      case DriverModuleStateKind.failure:
        return _MessageState(
          title: 'Falha ao carregar',
          message:
              state.message ?? 'Não foi possível carregar o Driver Module.',
          onRetry: _controller.load,
        );
      case DriverModuleStateKind.nativeReadinessBlocked:
      case DriverModuleStateKind.appInventoryBlocked:
      case DriverModuleStateKind.ready:
        return _DriverModuleReadinessState(
          controller: _controller,
          stateKind: state.kind,
          message: state.message,
          bootstrap: state.bootstrap!,
          nativeStatus: state.nativeStatus!,
          ready: state.kind == DriverModuleStateKind.ready,
        );
    }
  }
}

class _DriverModuleReadinessState extends StatelessWidget {
  const _DriverModuleReadinessState({
    required this.controller,
    required this.stateKind,
    required this.message,
    required this.bootstrap,
    required this.nativeStatus,
    required this.ready,
  });

  final DriverModuleController controller;
  final DriverModuleStateKind stateKind;
  final String? message;
  final DriverModuleBootstrap bootstrap;
  final DriverNativeFoundationStatus nativeStatus;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final blockers = controller.describeMissingCapabilities();
    final installedApps = nativeStatus.installedTargetAppsCount;
    final readyApps = nativeStatus.readyTargetAppsCount;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          _titleForState(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(_subtitleForState()),
        if (message != null) ...[
          const SizedBox(height: 12),
          Card(
            color: ready
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message!),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _SectionCard(
          key: const ValueKey('driver-module-readiness-section'),
          title: 'Readiness do módulo',
          children: [
            _StatusRow(
              label: 'Estado agregado',
              value: ready ? 'Apto' : 'Pendente',
            ),
            _StatusRow(
              label: 'Readiness nativo',
              value: nativeStatus.moduleReady ? 'Apto' : 'Pendente',
            ),
            _StatusRow(
              label: 'Inventário por app',
              value: controller.inventorySummaryLabel(),
            ),
            _StatusRow(
              label: 'Bridge nativa disponível',
              value: nativeStatus.nativeBridgeAvailable ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Apps-alvo encontrados',
              value: '$installedApps de ${nativeStatus.targetApps.length}',
            ),
            _StatusRow(
              label: 'Apps aptos para a próxima fase',
              value: '$readyApps de ${nativeStatus.targetApps.length}',
            ),
            const SizedBox(height: 12),
            Text(
              ready ? 'Onboarding técnico concluído.' : 'Onboarding técnico',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Abra a acessibilidade. 2. Habilite o Driver Module. 3. Volte para o app para reavaliar o readiness automaticamente.',
            ),
            const SizedBox(height: 16),
            if (blockers.isEmpty)
              const Text('Nenhum bloqueio nativo pendente.')
            else
              ...blockers.map(
                (blocker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blocker.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(blocker.description),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (!ready && nativeStatus.canOpenAccessibilitySettings)
                  FilledButton(
                    key: const ValueKey(
                      'driver-module-open-accessibility-settings-button',
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final opened =
                          await controller.openAccessibilitySettings();
                      if (!context.mounted) {
                        return;
                      }
                      if (!opened) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível abrir a tela de acessibilidade.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Abrir acessibilidade'),
                  ),
                OutlinedButton(
                  key: const ValueKey('driver-module-refresh-native-button'),
                  onPressed: controller.refreshNativeStatus,
                  child: const Text('Atualizar status'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          key: const ValueKey('driver-module-app-inventory-section'),
          title: 'Inventário operacional por app',
          children: [
            ...nativeStatus.targetApps.map(
              (target) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TargetAppCard(
                  target: target,
                  missingCapabilities: controller.describeAppMissingCapabilities(
                    target,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          key: const ValueKey('driver-module-bootstrap-section'),
          title: 'Base do módulo',
          children: [
            Text('Espaço atual: ${bootstrap.spaceId}'),
            Text(
              '${bootstrap.targetCity}, ${bootstrap.targetState}, ${bootstrap.targetCountry}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bootstrap.providers
                  .map((provider) => Chip(label: Text(provider.label)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          key: const ValueKey('driver-module-native-section'),
          title: 'Bridge Android',
          children: [
            _StatusRow(
              label: 'Canal nativo pronto',
              value: nativeStatus.methodChannelReady ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'AccessibilityService declarado',
              value: nativeStatus.accessibilityServiceDeclared ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'AccessibilityService habilitado',
              value: nativeStatus.accessibilityServiceEnabled ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Configurações de acessibilidade disponíveis',
              value: nativeStatus.canOpenAccessibilitySettings ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Android Auto preparado',
              value: nativeStatus.androidAutoPrepared ? 'Sim' : 'Não',
            ),
            _StatusRow(label: 'Package Android', value: nativeStatus.packageName),
            _StatusRow(label: 'MethodChannel', value: nativeStatus.methodChannel),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionCard(
          title: 'Próxima rodada',
          children: [
            Text(
              'A próxima etapa já pode consumir este readiness para iniciar o primeiro fluxo técnico do módulo sem retrabalho estrutural.',
            ),
          ],
        ),
      ],
    );
  }

  String _titleForState() {
    switch (stateKind) {
      case DriverModuleStateKind.ready:
        return 'Driver Module apto';
      case DriverModuleStateKind.appInventoryBlocked:
        return 'Driver Module em inventário';
      case DriverModuleStateKind.nativeReadinessBlocked:
        return 'Driver Module em readiness';
      case DriverModuleStateKind.loading:
      case DriverModuleStateKind.sessionUnavailable:
      case DriverModuleStateKind.backendBlocked:
      case DriverModuleStateKind.failure:
        return 'Driver Module';
    }
  }

  String _subtitleForState() {
    switch (stateKind) {
      case DriverModuleStateKind.ready:
        return 'Base pronta para a próxima fase técnica.';
      case DriverModuleStateKind.appInventoryBlocked:
        return 'O serviço central já está pronto, mas ainda falta pelo menos um app-alvo apto para seguir.';
      case DriverModuleStateKind.nativeReadinessBlocked:
        return 'A base do módulo já conhece o Espaço e o Android. Falta fechar as capabilities obrigatórias para seguir.';
      case DriverModuleStateKind.loading:
      case DriverModuleStateKind.sessionUnavailable:
      case DriverModuleStateKind.backendBlocked:
      case DriverModuleStateKind.failure:
        return '';
    }
  }
}

class _TargetAppCard extends StatelessWidget {
  const _TargetAppCard({
    required this.target,
    required this.missingCapabilities,
  });

  final DriverTargetAppStatus target;
  final List<DriverModuleCapabilityCopy> missingCapabilities;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${target.label} · ${_statusLabel()}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Package: ${target.packageName}'),
            if (target.detectedPackageName != null &&
                target.detectedPackageName != target.packageName)
              Text('Package detectado: ${target.detectedPackageName}'),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Instalado',
              value: target.installed ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Habilitado no sistema',
              value: target.enabledInSystem ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Launch intent disponível',
              value: target.launchIntentAvailable ? 'Sim' : 'Não',
            ),
            _StatusRow(
              label: 'Readiness por app',
              value: target.appReady ? 'Apto' : 'Pendente',
            ),
            const SizedBox(height: 12),
            if (missingCapabilities.isEmpty)
              const Text('Nenhuma capability pendente para este app.')
            else
              ...missingCapabilities.map(
                (capability) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${capability.title}: ${capability.description}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (!target.installed) {
      return 'Ausente';
    }
    if (target.appReady) {
      return 'Apto';
    }
    return 'Pendente';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
