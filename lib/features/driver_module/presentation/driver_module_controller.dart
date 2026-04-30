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

  const DriverModuleState.loading() : this(kind: DriverModuleStateKind.loading);

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
          message:
              'Não foi possível reavaliar o readiness após o retorno ao app.',
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

  Future<void> saveSignalPreferences(DriverSignalPreferencesInput input) async {
    final bootstrap = _state.bootstrap;
    if (bootstrap == null) {
      return;
    }

    try {
      final nativeStatus = await _driverNativeBridge.saveSignalPreferences(
        input: input,
      );
      _setState(
        _buildState(
          bootstrap,
          nativeStatus,
          message: 'Parâmetros do farol salvos no dispositivo.',
        ),
      );
    } on DriverSignalPreferencesValidationException catch (error) {
      _setState(_state.copyWith(message: error.validationErrors.join(' ')));
    } catch (_) {
      _setState(
        _state.copyWith(
          message: 'Não foi possível salvar os parâmetros do farol.',
        ),
      );
    }
  }

  Future<void> resetSignalPreferences() async {
    final bootstrap = _state.bootstrap;
    if (bootstrap == null) {
      return;
    }

    try {
      final nativeStatus = await _driverNativeBridge.resetSignalPreferences();
      _setState(
        _buildState(
          bootstrap,
          nativeStatus,
          message: 'Parâmetros do farol restaurados para o padrão do app.',
        ),
      );
    } catch (_) {
      _setState(
        _state.copyWith(
          message: 'Não foi possível restaurar os parâmetros padrão do farol.',
        ),
      );
    }
  }

  List<DriverModuleCapabilityCopy> describeMissingCapabilities() {
    final keys = _state.nativeStatus?.missingCapabilities ?? const <String>[];
    return keys.map(_mapCapability).toList();
  }

  DriverModuleState _buildState(
    DriverModuleBootstrap bootstrap,
    DriverNativeFoundationStatus nativeStatus, {
    String? message,
  }) {
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

  String contextSummaryLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null) {
      return 'Indisponível';
    }
    if (!nativeStatus.hasCapturedProviderContexts) {
      return 'Pendente';
    }
    return 'Capturado';
  }

  String signalLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null) {
      return 'Indisponível';
    }
    return nativeStatus.signal.label;
  }

  String currentProviderLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null || !currentContext.hasProvider) {
      return 'Nenhum provider em foco';
    }
    return currentContext.label;
  }

  String currentSemanticStateLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'Indisponível';
    }
    return currentContext.semanticState.label;
  }

  String currentSemanticStateCode() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'INDISPONIVEL';
    }
    return currentContext.semanticState.code;
  }

  String currentSemanticSummary() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'Sem leitura local disponível.';
    }
    return currentContext.semanticState.summary;
  }

  String currentSemanticConfidenceLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'Indisponível';
    }
    return currentContext.semanticState.confidence;
  }

  String currentSemanticDetectedSignalsLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'Nenhum sinal detectado.';
    }
    final signals = currentContext.semanticState.detectedSignals;
    if (signals.isEmpty) {
      return 'Nenhum sinal detectado.';
    }
    return signals.join(' | ');
  }

  String lastOfferStatusLabel() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    if (lastOffer == null || !lastOffer.detected || lastOffer.ageMs == null) {
      return 'Nenhuma oferta recente detectada.';
    }
    final ageSeconds = (lastOffer.ageMs! / 1000).toStringAsFixed(1);
    return 'Detectada há ${ageSeconds.replaceAll('.', ',')}s';
  }

  String lastOfferSummary() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    return lastOffer?.summary ?? 'Nenhuma oferta recente preservada.';
  }

  String lastOfferSignalsLabel() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    if (lastOffer == null || lastOffer.signals.isEmpty) {
      return 'Nenhum sinal recente de oferta.';
    }
    return lastOffer.signals.join(' | ');
  }

  String lastOfferClassificationLabel() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    if (lastOffer == null || !lastOffer.detected) {
      return 'Nenhuma classificação recente.';
    }
    return lastOffer.classification ?? 'Sem classificação';
  }

  String lastOfferActionabilityLabel() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    if (lastOffer == null || !lastOffer.detected) {
      return 'Não';
    }
    return lastOffer.isActionable ? 'Sim' : 'Não';
  }

  String lastOfferMissingRequirementsLabel() {
    final lastOffer = _state.nativeStatus?.lastOffer;
    if (lastOffer == null || lastOffer.missingRequirements.isEmpty) {
      return 'Nenhum requisito pendente.';
    }
    return lastOffer.missingRequirements.join(' | ');
  }

  String currentSemanticMissingRequirementsLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null ||
        currentContext.semanticState.missingRequirements.isEmpty) {
      return 'Nenhum requisito pendente.';
    }
    return currentContext.semanticState.missingRequirements.join(' | ');
  }

  String structuredOfferStatusLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.structuredOfferPresent) {
      return 'Nenhuma oferta estruturada no contexto atual.';
    }
    return nativeStatus.offerActionable
        ? 'Oferta estruturada acionável disponível.'
        : 'Oferta estruturada parcial disponível.';
  }

  String structuredOfferClassificationLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.structuredOfferPresent) {
      return 'Nenhuma classificação disponível.';
    }
    return nativeStatus.offerClassification ?? 'Sem classificação';
  }

  String structuredOfferActionabilityLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.structuredOfferPresent) {
      return 'Não';
    }
    return nativeStatus.offerActionable ? 'Sim' : 'Não';
  }

  String structuredOfferValueLabel() {
    final offer = _state.nativeStatus?.structuredOffer;
    return offer?.fareAmountText ?? 'Não identificado';
  }

  String structuredOfferProductLabel() {
    final offer = _state.nativeStatus?.structuredOffer;
    return offer?.productName ?? 'Não identificado';
  }

  String structuredOfferPickupLabel() {
    final offer = _state.nativeStatus?.structuredOffer;
    if (offer == null) {
      return 'Não identificado';
    }
    final parts = [
      if (offer.pickupEtaText != null) offer.pickupEtaText!,
      if (offer.pickupDistanceText != null) offer.pickupDistanceText!,
    ];
    return parts.isEmpty ? 'Não identificado' : parts.join(' | ');
  }

  String structuredOfferTripLabel() {
    final offer = _state.nativeStatus?.structuredOffer;
    if (offer == null) {
      return 'Não identificado';
    }
    final parts = [
      if (offer.tripDurationText != null) offer.tripDurationText!,
      if (offer.tripDistanceText != null) offer.tripDistanceText!,
    ];
    return parts.isEmpty ? 'Não identificado' : parts.join(' | ');
  }

  String structuredOfferPrimaryLocationLabel() {
    return _state.nativeStatus?.structuredOffer?.primaryLocationText ??
        'Não identificado';
  }

  String structuredOfferSecondaryLocationLabel() {
    return _state.nativeStatus?.structuredOffer?.secondaryLocationText ??
        'Não identificado';
  }

  String structuredOfferCtaLabel() {
    return _state.nativeStatus?.structuredOffer?.ctaText ?? 'Não identificado';
  }

  String structuredOfferConfidenceLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.structuredOfferPresent) {
      return 'Indisponível';
    }
    return nativeStatus.offerParsingConfidence ?? 'LOW';
  }

  String structuredOfferMissingFieldsLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || nativeStatus.offerMissingFields.isEmpty) {
      return 'Nenhum campo ausente.';
    }
    return nativeStatus.offerMissingFields.join(' | ');
  }

  String offerSignalStatusLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Nenhum farol calculado para a oferta atual.';
    }
    final color = nativeStatus.offerSignalColor ?? 'RED';
    return switch (color) {
      'GREEN' => 'Verde',
      'YELLOW' => 'Amarelo',
      'RED' => 'Vermelho',
      _ => color,
    };
  }

  String offerSignalReasonLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Sem motivo calculado.';
    }
    return nativeStatus.offerSignalReason ?? 'Sem motivo calculado.';
  }

  String offerSignalFarePerKmLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Não calculado';
    }
    return nativeStatus.farePerKmText ?? 'Não calculado';
  }

  String offerSignalFarePerHourLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Não calculado';
    }
    return nativeStatus.farePerHourText ?? 'Não calculado';
  }

  String offerSignalEstimatedDistanceLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Não calculado';
    }
    return nativeStatus.estimatedTotalDistanceText ?? 'Não calculado';
  }

  String offerSignalEstimatedDurationLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Não calculado';
    }
    return nativeStatus.estimatedTotalDurationText ?? 'Não calculado';
  }

  String offerSignalWarningsLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || nativeStatus.offerSignalWarnings.isEmpty) {
      return 'Nenhum aviso.';
    }
    return nativeStatus.offerSignalWarnings.join(' | ');
  }

  String offerSignalRuleVersionLabel() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.offerSignalPresent) {
      return 'Indisponível';
    }
    return nativeStatus.signalRuleVersion ?? 'Indisponível';
  }

  DriverSignalPreferencesStatus? signalPreferences() {
    return _state.nativeStatus?.signalPreferences;
  }

  String signalPreferencesSourceLabel() {
    final preferences = _state.nativeStatus?.signalPreferences;
    if (preferences == null) {
      return 'Indisponível';
    }
    return switch (preferences.source) {
      'USER_CONFIGURED' => 'Usando configuração do motorista',
      _ => 'Usando padrão do app',
    };
  }

  String signalPreferencesUpdatedAtLabel() {
    final preferences = _state.nativeStatus?.signalPreferences;
    if (preferences == null || preferences.updatedAt.isEmpty) {
      return 'Sem atualização manual';
    }
    return preferences.updatedAt;
  }

  String contextValidityLabel() {
    final currentContext = _state.nativeStatus?.currentContext;
    if (currentContext == null) {
      return 'Indisponível';
    }
    switch (currentContext.validity) {
      case 'VALID':
        return 'Válido';
      case 'STALE':
        return 'Recente, fora de foco';
      case 'INCOMPLETE':
        return 'Incompleto';
      case 'EXPIRED':
        return 'Expirado';
      case 'INVALID':
        return 'Inválido';
      default:
        return currentContext.validity;
    }
  }

  String acceptCommandLabel() {
    final acceptCommand = _state.nativeStatus?.acceptCommand;
    if (acceptCommand == null) {
      return 'Indisponível';
    }
    switch (acceptCommand.state) {
      case 'IDLE':
        return 'Ocioso';
      case 'PENDING_EXECUTOR':
        return 'Pendente no executor';
      case 'EXECUTOR_READY':
        return 'Executor pronto';
      case 'BLOCKED':
        return 'Bloqueado';
      case 'INVALIDATED':
        return 'Invalidado';
      default:
        return acceptCommand.state;
    }
  }

  bool canRequestAcceptCommand() {
    final nativeStatus = _state.nativeStatus;
    if (nativeStatus == null || !nativeStatus.moduleReady) {
      return false;
    }
    final currentContext = nativeStatus.currentContext;
    if (!currentContext.hasProvider ||
        !currentContext.isFresh ||
        !currentContext.isActionable) {
      return false;
    }
    final targetApp = nativeStatus.targetApps
        .where((target) => target.key == currentContext.providerKey)
        .firstOrNull;
    return targetApp?.appReady == true;
  }

  Future<void> requestAcceptCommand() async {
    final bootstrap = _state.bootstrap;
    if (bootstrap == null) {
      return;
    }

    try {
      final nativeStatus = await _driverNativeBridge.requestAcceptCommand();
      _setState(
        _buildState(
          bootstrap,
          nativeStatus,
          message: _acceptCommandMessage(nativeStatus.acceptCommand),
        ),
      );
    } catch (_) {
      _setState(
        DriverModuleState(
          kind: DriverModuleStateKind.failure,
          bootstrap: bootstrap,
          message: 'Não foi possível registrar o comando unificado no nativo.',
        ),
      );
    }
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

  String _acceptCommandMessage(DriverAcceptCommandStatus acceptCommand) {
    switch (acceptCommand.state) {
      case 'PENDING_EXECUTOR':
        return 'Comando registrado no núcleo nativo. O executor real continua restrito ao AccessibilityService.';
      case 'EXECUTOR_READY':
        return 'Comando reconhecido pelo executor nativo. A rodada ainda não executa clique em apps terceiros.';
      case 'BLOCKED':
        return 'O comando unificado foi bloqueado: ${_mapCommandReason(acceptCommand.reason)}.';
      case 'INVALIDATED':
        return 'O comando unificado perdeu validade: ${_mapCommandReason(acceptCommand.reason)}.';
      default:
        return 'O caminho unificado de comando está pronto, mas ainda sem execução ativa.';
    }
  }

  String _mapCommandReason(String? reason) {
    switch (reason) {
      case 'MODULE_NOT_READY':
        return 'o módulo ainda não está pronto';
      case 'NO_PROVIDER_CONTEXT':
        return 'não há contexto recente de provider';
      case 'TARGET_APP_NOT_READY':
        return 'o app atual ainda não está apto';
      case 'CONTEXT_TTL_EXPIRED':
        return 'o contexto recente expirou';
      case 'CONTEXT_NOT_CAPTURED':
        return 'o provider entrou em foco sem contexto suficiente';
      case 'PROVIDER_CHANGED':
        return 'o provider atual mudou antes do executor assumir';
      case 'PROVIDER_OUT_OF_FOCUS':
        return 'o provider saiu de foco';
      default:
        return reason ?? 'motivo não informado';
    }
  }

  void _setState(DriverModuleState nextState) {
    _state = nextState;
    notifyListeners();
  }
}
