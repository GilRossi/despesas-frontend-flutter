import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_bootstrap.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_repository.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
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

class _DriverModuleScreenState extends State<DriverModuleScreen> {
  bool _loading = true;
  String? _errorMessage;
  bool _moduleUnavailable = false;
  DriverModuleBootstrap? _bootstrap;
  DriverNativeFoundationStatus? _nativeStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _moduleUnavailable = false;
    });

    try {
      final bootstrap = await widget.driverModuleRepository.fetchBootstrap();
      final nativeStatus = await widget.driverNativeBridge.getFoundationStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrap = bootstrap;
        _nativeStatus = nativeStatus;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _moduleUnavailable = error.statusCode == 403;
        _errorMessage = error.statusCode == 403 ? null : error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível carregar o Driver Module.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.sessionController.currentUser;
    final isPlatformAdmin = user?.role == 'PLATFORM_ADMIN';
    final hasSpace = user?.householdId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Module')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !hasSpace || isPlatformAdmin
            ? _MessageState(
                title: 'Driver Module indisponível',
                message:
                    'Esta base do módulo só pode ser usada por um usuário com Espaço ativo.',
                onRetry: _load,
              )
            : _moduleUnavailable
            ? _MessageState(
                title: 'Driver Module indisponível',
                message:
                    'O módulo Motorista não está habilitado neste Espaço.',
                onRetry: _load,
              )
            : _errorMessage != null
            ? _MessageState(
                title: 'Falha ao carregar',
                message:
                    _errorMessage ?? 'Não foi possível carregar o Driver Module.',
                onRetry: _load,
              )
            : _DriverModuleSuccessState(
                bootstrap: _bootstrap!,
                nativeStatus: _nativeStatus!,
              ),
      ),
    );
  }
}

class _DriverModuleSuccessState extends StatelessWidget {
  const _DriverModuleSuccessState({
    required this.bootstrap,
    required this.nativeStatus,
  });

  final DriverModuleBootstrap bootstrap;
  final DriverNativeFoundationStatus nativeStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Fundação inicial do módulo híbrido Flutter + Android.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
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
              'A próxima etapa pode adicionar o primeiro fluxo técnico do módulo sem reabrir a governança por Espaço.',
            ),
          ],
        ),
      ],
    );
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
