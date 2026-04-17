import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_bootstrap.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_repository.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
import 'package:flutter/foundation.dart';

enum DriverModuleStateKind {
  loading,
  sessionUnavailable,
  backendBlocked,
  nativeReadinessBlocked,
  appInventoryBlocked,
  ready,
  failure,
}

class DriverModuleState {
  const DriverModuleState({
    required this.kind,
    this.bootstrap,
    this.nativeStatus,
    this.message,
  });

  const DriverModuleState.loading()
    : this(kind: DriverModuleStateKind.loading);

  final DriverModuleStateKind kind;
  final DriverModuleBootstrap? bootstrap;
  final DriverNativeFoundationStatus? nativeStatus;
  final String? message;

  bool get canProceed => kind == DriverModuleStateKind.ready;

  DriverModuleState copyWith({
    DriverModuleStateKind? kind,
    DriverModuleBootstrap? bootstrap,
    DriverNativeFoundationStatus? nativeStatus,
    String? message,
  }) {
    return DriverModuleState(
      kind: kind ?? this.kind,
      bootstrap: bootstrap ?? this.bootstrap,
      nativeStatus: nativeStatus ?? this.nativeStatus,
      message: message,
    );
  }
}

class DriverModuleCapabilityCopy {
  const DriverModuleCapabilityCopy({
    required this.key,
    required this.title,
    required this.description,
  });

  final String key;
  final String title;
  final String description;
}

class DriverModuleController extends ChangeNotifier {
  DriverModuleController({
    required SessionController sessionController,
    required DriverModuleRepository driverModuleRepository,
    required DriverNativeBridge driverNativeBridge,
  }) : _sessionController = sessionController,
       _driverModuleRepository = driverModuleRepository,
       _driverNativeBridge = driverNativeBridge;

  final SessionController _sessionController;
  final DriverModuleRepository _driverModuleRepository;
  final DriverNativeBridge _driverNativeBridge;

  DriverModuleState _state = const DriverModuleState.loading();
  bool _awaitingAccessibilityReturn = false;
  DriverModuleState get state => _state;

  Future<void> load() async {
    final user = _sessionController.currentUser;
    final isPlatformAdmin = user?.role == 'PLATFORM_ADMIN';
    final hasSpace = user?.householdId != null;

    if (!hasSpace || isPlatformAdmin) {
      _setState(
        const DriverModuleState(
          kind: DriverModuleStateKind.sessionUnavailable,
          message:
              'Esta camada do módulo só pode ser usada por um usuário com Espaço ativo.',
        ),
      );
      return;
    }

    _setState(const DriverModuleState.loading());

    try {
      final bootstrap = await _driverModuleRepository.fetchBootstrap();
      final nativeStatus = await _driverNativeBridge.getFoundationStatus();
      _setState(_buildState(bootstrap, nativeStatus, message: null));
    } on ApiException catch (error) {
      if (error.statusCode == 403) {
        _setState(
          const DriverModuleState(
            kind: DriverModuleStateKind.backendBlocked,
            message: 'O módulo Motorista não está habilitado neste Espaço.',
          ),
        );
        return;
      }
      _setState(
        DriverModuleState(
          kind: DriverModuleStateKind.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      _setState(
        const DriverModuleState(
          kind: DriverModuleStateKind.failure,
          message: 'Não foi possível carregar o Driver Module.',
        ),
      );
    }
  }

  Future<void> refreshNativeStatus({String? message}) async {
    final bootstrap = _state.bootstrap;
    if (bootstrap == null) {
      return;
    }

    try {
      final nativeStatus = await _driverNativeBridge.getFoundationStatus();
      _setState(_buildState(bootstrap, nativeStatus, message: message));
    } catch (_) {
      _setState(
        DriverModuleState(
          kind: DriverModuleStateKind.failure,
          bootstrap: bootstrap,
          message: 'Não foi possível atualizar o readiness do Driver Module.',
        ),
      );
    }
  }

  Future<void> handleAppResumed() async {
    if (!_awaitingAccessibilityReturn) {
      await refreshNativeStatus();
      return;
    }

    _awaitingAccessibilityReturn = false;
    final bootstrap = _state.bootstrap;
    if (bootstrap == null) {
      return;
    }

    try {
      final nativeStatus = await _driverNativeBridge.getFoundationStatus();
      _setState(
        _buildState(
          bootstrap,
          nativeStatus,
          message: !nativeStatus.moduleReady
              ? 'O app voltou da acessibilidade, mas o Driver Module ainda não foi habilitado no sistema.'
              : nativeStatus.hasReadyTargetApps
              ? 'AccessibilityService habilitado no retorno. O módulo já pode seguir.'
              : 'O serviço central foi habilitado no retorno, mas ainda falta pelo menos um app-alvo apto.',
        ),
      );
    } catch (_) {
      _setState(
        DriverModuleState(
          kind: DriverModuleStateKind.failure,
          bootstrap: bootstrap,
          message: 'Não foi possível reavaliar o readiness após o retorno ao app.',
        ),
      );
    }
  }

  Future<bool> openAccessibilitySettings() async {
    final opened = await _driverNativeBridge.openAccessibilitySettings();
    if (opened) {
      _awaitingAccessibilityReturn = true;
      _setState(
        _state.copyWith(
          message:
              'Abra o Driver Module na acessibilidade, habilite o serviço e volte para o app.',
        ),
      );
    }
    return opened;
  }

  List<DriverModuleCapabilityCopy> describeMissingCapabilities() {
    final keys = _state.nativeStatus?.missingCapabilities ?? const <String>[];
    return keys.map(_mapCapability).toList();
  }

  DriverModuleState _buildState(
    DriverModuleBootstrap bootstrap,
    DriverNativeFoundationStatus nativeStatus,
    {String? message}
  ) {
    if (!nativeStatus.moduleReady) {
      return DriverModuleState(
        kind: DriverModuleStateKind.nativeReadinessBlocked,
        bootstrap: bootstrap,
        nativeStatus: nativeStatus,
        message:
            message ??
            'Ainda falta habilitar o serviço principal para liberar a próxima fase do módulo.',
      );
    }
    if (!nativeStatus.hasReadyTargetApps) {
      return DriverModuleState(
        kind: DriverModuleStateKind.appInventoryBlocked,
        bootstrap: bootstrap,
        nativeStatus: nativeStatus,
        message:
            message ??
            'O serviço central está pronto, mas nenhum app-alvo está apto para a próxima fase.',
      );
    }
    return DriverModuleState(
      kind: DriverModuleStateKind.ready,
      bootstrap: bootstrap,
      nativeStatus: nativeStatus,
      message: message ?? 'Readiness nativo fechado. O módulo já pode seguir.',
    );
  }

  String inventorySummaryLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null) {
      return 'Indisponível';
    }
    if (!nativeStatus.hasReadyTargetApps) {
      return 'Pendente';
    }
    return 'Pronto';
  }

  List<DriverModuleCapabilityCopy> describeAppMissingCapabilities(
    DriverTargetAppStatus target,
  ) {
    return target.missingCapabilities.map(_mapCapability).toList();
  }

  DriverModuleCapabilityCopy _mapCapability(String key) {
    switch (key) {
      case 'ACCESSIBILITY_SERVICE_NOT_DECLARED':
        return const DriverModuleCapabilityCopy(
          key: 'ACCESSIBILITY_SERVICE_NOT_DECLARED',
          title: 'AccessibilityService não declarado',
          description:
              'O app não encontrou a declaração nativa do serviço de acessibilidade.',
        );
      case 'ACCESSIBILITY_SERVICE_DISABLED':
        return const DriverModuleCapabilityCopy(
          key: 'ACCESSIBILITY_SERVICE_DISABLED',
          title: 'Serviço central desabilitado',
          description:
              'Ative o Driver Module na acessibilidade para liberar a próxima fase técnica.',
        );
      case 'ACCESSIBILITY_SETTINGS_UNAVAILABLE':
        return const DriverModuleCapabilityCopy(
          key: 'ACCESSIBILITY_SETTINGS_UNAVAILABLE',
          title: 'Configurações de acessibilidade indisponíveis',
          description:
              'O app não conseguiu abrir a tela de acessibilidade deste dispositivo.',
        );
      case 'PACKAGE_NOT_INSTALLED':
        return const DriverModuleCapabilityCopy(
          key: 'PACKAGE_NOT_INSTALLED',
          title: 'App não instalado',
          description:
              'O package aprovado ainda não foi encontrado neste device.',
        );
      case 'APP_DISABLED':
        return const DriverModuleCapabilityCopy(
          key: 'APP_DISABLED',
          title: 'App desabilitado no sistema',
          description:
              'O package existe, mas está desabilitado no Android e ainda não pode seguir.',
        );
      case 'LAUNCH_INTENT_UNAVAILABLE':
        return const DriverModuleCapabilityCopy(
          key: 'LAUNCH_INTENT_UNAVAILABLE',
          title: 'Launch intent indisponível',
          description:
              'O Android não encontrou uma activity principal para abrir este app.',
        );
      default:
        return DriverModuleCapabilityCopy(
          key: key,
          title: key,
          description: 'Há uma capability pendente para seguir.',
        );
    }
  }

  void _setState(DriverModuleState nextState) {
    _state = nextState;
    notifyListeners();
  }
}
