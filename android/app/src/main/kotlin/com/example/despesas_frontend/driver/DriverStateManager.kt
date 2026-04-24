package com.example.despesas_frontend.driver

import java.time.Duration
import java.time.Instant
import java.util.Locale

object DriverStateManager {
    private const val CONTEXT_TTL_SECONDS = 15L

    private var packageName: String = ""
    private var methodChannel: String = ""
    private var nativeBridgeAvailable: Boolean = false
    private var methodChannelReady: Boolean = false
    private var accessibilityServiceDeclared: Boolean = false
    private var accessibilityServiceEnabled: Boolean = false
    private var canOpenAccessibilitySettings: Boolean = false
    private var missingCapabilities: List<String> = emptyList()
    private var targetApps: List<DriverTargetAppSnapshot> = emptyList()
    private var androidAutoPrepared: Boolean = false

    private val providerContextsByKey = linkedMapOf<String, DriverProviderContextSnapshot>()

    private var focusedProviderKey: String? = null
    private var focusedProviderLabel: String? = null
    private var focusedPackageName: String? = null
    private var lastInvalidationReason: String? = "NO_CONTEXT"

    private var acceptCommand = DriverAcceptCommandSnapshot.idle()

    @Synchronized
    fun resetForTest() {
        packageName = ""
        methodChannel = ""
        nativeBridgeAvailable = false
        methodChannelReady = false
        accessibilityServiceDeclared = false
        accessibilityServiceEnabled = false
        canOpenAccessibilitySettings = false
        missingCapabilities = emptyList()
        targetApps = emptyList()
        androidAutoPrepared = false
        providerContextsByKey.clear()
        focusedProviderKey = null
        focusedProviderLabel = null
        focusedPackageName = null
        lastInvalidationReason = "NO_CONTEXT"
        acceptCommand = DriverAcceptCommandSnapshot.idle()
    }

    @Synchronized
    fun updateFoundation(
        packageName: String,
        methodChannel: String,
        nativeBridgeAvailable: Boolean,
        methodChannelReady: Boolean,
        accessibilityServiceDeclared: Boolean,
        accessibilityServiceEnabled: Boolean,
        canOpenAccessibilitySettings: Boolean,
        missingCapabilities: List<String>,
        targetApps: List<DriverTargetAppSnapshot>,
        androidAutoPrepared: Boolean,
    ) {
        this.packageName = packageName
        this.methodChannel = methodChannel
        this.nativeBridgeAvailable = nativeBridgeAvailable
        this.methodChannelReady = methodChannelReady
        this.accessibilityServiceDeclared = accessibilityServiceDeclared
        this.accessibilityServiceEnabled = accessibilityServiceEnabled
        this.canOpenAccessibilitySettings = canOpenAccessibilitySettings
        this.missingCapabilities = missingCapabilities
        this.targetApps = targetApps
        this.androidAutoPrepared = androidAutoPrepared
    }

    @Synchronized
    fun recordProviderEvent(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        eventType: String,
        texts: List<String>,
    ) {
        val now = Instant.now()
        val previousProviderKey = focusedProviderKey
        focusedProviderKey = providerKey
        focusedProviderLabel = providerLabel
        focusedPackageName = packageName
        lastInvalidationReason = null

        if (texts.isNotEmpty()) {
            val semanticState = normalizeSemanticState(
                providerKey = providerKey,
                inFocus = true,
                texts = texts,
                validity = "VALID",
                invalidationReason = null,
            )
            providerContextsByKey[providerKey] = DriverProviderContextSnapshot(
                providerKey = providerKey,
                label = providerLabel,
                packageName = packageName,
                eventType = eventType,
                capturedAt = now.toString(),
                texts = texts,
                semanticState = semanticState,
            )
        }

        if (acceptCommand.state == "PENDING_EXECUTOR" &&
            previousProviderKey != null &&
            previousProviderKey != providerKey &&
            acceptCommand.targetProviderKey != providerKey
        ) {
            acceptCommand = acceptCommand.invalidated(
                reason = "PROVIDER_CHANGED",
                updatedAt = now,
            )
        }

        advanceAcceptCommandIfPossible(now)
    }

    @Synchronized
    fun markProviderOutOfFocus(packageName: String) {
        if (focusedProviderKey == null) {
            return
        }
        if (packageName.equals(focusedPackageName, ignoreCase = true)) {
            return
        }
        focusedProviderKey = null
        focusedProviderLabel = null
        focusedPackageName = null
        lastInvalidationReason = "PROVIDER_OUT_OF_FOCUS"
    }

    @Synchronized
    fun requestAcceptCommand(source: String): DriverModuleNativeSnapshot {
        val now = Instant.now()
        val currentContext = resolveCurrentContext(now)
        val targetProviderKey = currentContext.providerKey.takeIf { it.isNotBlank() }
        val targetPackageName = currentContext.packageName.takeIf { it.isNotBlank() }
        val canQueue = moduleOperationallyReady() &&
            targetProviderKey != null &&
            targetAppReady(targetProviderKey) &&
            currentContext.isActionable

        acceptCommand = if (canQueue) {
            DriverAcceptCommandSnapshot.pending(
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                updatedAt = now,
            )
        } else {
            DriverAcceptCommandSnapshot.blocked(
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                updatedAt = now,
                reason = commandBlockReason(currentContext, targetProviderKey),
            )
        }

        advanceAcceptCommandIfPossible(now)
        return buildSnapshot(now)
    }

    @Synchronized
    fun snapshot(): DriverModuleNativeSnapshot {
        return buildSnapshot(Instant.now())
    }

    private fun buildSnapshot(now: Instant): DriverModuleNativeSnapshot {
        reconcileAcceptCommand(now)
        val currentContext = resolveCurrentContext(now)
        return DriverModuleNativeSnapshot(
            packageName = packageName,
            methodChannel = methodChannel,
            nativeBridgeAvailable = nativeBridgeAvailable,
            methodChannelReady = methodChannelReady,
            accessibilityServiceDeclared = accessibilityServiceDeclared,
            accessibilityServiceEnabled = accessibilityServiceEnabled,
            canOpenAccessibilitySettings = canOpenAccessibilitySettings,
            moduleReady = missingCapabilities.isEmpty(),
            missingCapabilities = missingCapabilities,
            targetApps = targetApps,
            providerContexts = providerContextsByKey.values.toList(),
            signal = buildSignal(currentContext),
            currentContext = currentContext,
            acceptCommand = acceptCommand,
            contextTtlSeconds = CONTEXT_TTL_SECONDS.toInt(),
            androidAutoPrepared = androidAutoPrepared,
        )
    }

    private fun buildSignal(currentContext: DriverCurrentContextSnapshot): DriverOperationalSignalSnapshot {
        if (!moduleOperationallyReady()) {
            return DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = "MODULE_BLOCKED",
            )
        }

        val providerKey = currentContext.providerKey.takeIf { it.isNotBlank() }
        if (providerKey != null && !targetAppReady(providerKey)) {
            return DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = "PROVIDER_NOT_READY",
            )
        }

        return when (currentContext.validity) {
            "EXPIRED", "INVALID" -> DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = currentContext.invalidationReason ?: "NO_CONTEXT",
            )
            else -> when (currentContext.semanticState.code) {
                "RELEVANT_CONTEXT" -> DriverOperationalSignalSnapshot(
                    color = "GREEN",
                    label = "Verde",
                    reason = "RELEVANT_CONTEXT_DETECTED",
                )
                "NO_ACTIVE_PROVIDER" -> DriverOperationalSignalSnapshot(
                    color = "RED",
                    label = "Vermelho",
                    reason = "NO_ACTIVE_PROVIDER",
                )
                else -> DriverOperationalSignalSnapshot(
                    color = "YELLOW",
                    label = "Amarelo",
                    reason = currentContext.semanticState.code,
                )
            }
        }
    }

    private fun resolveCurrentContext(now: Instant): DriverCurrentContextSnapshot {
        val focusedProviderKey = focusedProviderKey
        val focusedProviderLabel = focusedProviderLabel
        val focusedPackageName = focusedPackageName

        if (focusedProviderKey != null &&
            focusedProviderLabel != null &&
            focusedPackageName != null
        ) {
            val context = providerContextsByKey[focusedProviderKey]
            if (context == null) {
                return DriverCurrentContextSnapshot(
                    providerKey = focusedProviderKey,
                    label = focusedProviderLabel,
                    packageName = focusedPackageName,
                    eventType = "",
                    capturedAt = "",
                    texts = emptyList(),
                    inFocus = true,
                    validity = "INCOMPLETE",
                    validUntil = "",
                    invalidationReason = "CONTEXT_NOT_CAPTURED",
                    semanticState = normalizeSemanticState(
                        providerKey = focusedProviderKey,
                        inFocus = true,
                        texts = emptyList(),
                        validity = "INCOMPLETE",
                        invalidationReason = "CONTEXT_NOT_CAPTURED",
                    ),
                )
            }
            return buildContextSnapshot(
                snapshot = context,
                inFocus = true,
                now = now,
                defaultInvalidationReason = null,
            )
        }

        val latestContext = providerContextsByKey.values.maxByOrNull { snapshot ->
            Instant.parse(snapshot.capturedAt)
        }
        if (latestContext != null) {
            return buildContextSnapshot(
                snapshot = latestContext,
                inFocus = false,
                now = now,
                defaultInvalidationReason = lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS",
            )
        }

        return DriverCurrentContextSnapshot(
            providerKey = "",
            label = "",
            packageName = "",
            eventType = "",
            capturedAt = "",
            texts = emptyList(),
            inFocus = false,
            validity = "INVALID",
            validUntil = "",
            invalidationReason = lastInvalidationReason ?: "NO_CONTEXT",
            semanticState = DriverSemanticStateSnapshot(
                code = "NO_ACTIVE_PROVIDER",
                label = "Sem provider ativo",
                summary = "Abra Uber Driver ou 99 Motorista para iniciar a leitura local.",
                contextRelevant = false,
            ),
        )
    }

    private fun buildContextSnapshot(
        snapshot: DriverProviderContextSnapshot,
        inFocus: Boolean,
        now: Instant,
        defaultInvalidationReason: String?,
    ): DriverCurrentContextSnapshot {
        val capturedAt = Instant.parse(snapshot.capturedAt)
        val validUntil = capturedAt.plusSeconds(CONTEXT_TTL_SECONDS)
        val expired = now.isAfter(validUntil)
        val validity = when {
            expired -> "EXPIRED"
            inFocus -> "VALID"
            else -> "STALE"
        }
        val invalidationReason = when {
            expired -> "CONTEXT_TTL_EXPIRED"
            inFocus -> null
            else -> defaultInvalidationReason
        }
        return DriverCurrentContextSnapshot(
            providerKey = snapshot.providerKey,
            label = snapshot.label,
            packageName = snapshot.packageName,
            eventType = snapshot.eventType,
            capturedAt = snapshot.capturedAt,
            texts = snapshot.texts,
            inFocus = inFocus,
            validity = validity,
            validUntil = validUntil.toString(),
            invalidationReason = invalidationReason,
            semanticState = normalizeSemanticState(
                providerKey = snapshot.providerKey,
                inFocus = inFocus,
                texts = snapshot.texts,
                validity = validity,
                invalidationReason = invalidationReason,
            ),
        )
    }

    private fun normalizeSemanticState(
        providerKey: String,
        inFocus: Boolean,
        texts: List<String>,
        validity: String,
        invalidationReason: String?,
    ): DriverSemanticStateSnapshot {
        if (providerKey.isBlank()) {
            return DriverSemanticStateSnapshot(
                code = "NO_ACTIVE_PROVIDER",
                label = "Sem provider ativo",
                summary = "Abra Uber Driver ou 99 Motorista para iniciar a leitura local.",
                contextRelevant = false,
            )
        }

        if (validity == "EXPIRED") {
            return DriverSemanticStateSnapshot(
                code = "OUT_OF_FOCUS",
                label = "Fora de foco",
                summary = "O contexto recente expirou e precisa ser capturado de novo.",
                contextRelevant = false,
            )
        }

        if (!inFocus || invalidationReason == "PROVIDER_OUT_OF_FOCUS") {
            return DriverSemanticStateSnapshot(
                code = "OUT_OF_FOCUS",
                label = "Fora de foco",
                summary = "O app foi visto há pouco, mas não está em foco agora.",
                contextRelevant = false,
            )
        }

        val capturedTexts = texts
            .map { text -> text.trim() }
            .filter { text -> text.isNotBlank() }

        if (capturedTexts.isEmpty()) {
            return DriverSemanticStateSnapshot(
                code = "INSUFFICIENT_CONTEXT",
                label = "Contexto insuficiente",
                summary = "O provider está em foco, mas a captura local ainda é insuficiente.",
                contextRelevant = false,
            )
        }

        val permissionEvidence = matchingEvidence(
            capturedTexts,
            permissionOrConsentKeywords(providerKey),
        )
        if (permissionEvidence.isNotEmpty()) {
            return DriverSemanticStateSnapshot(
                code = "LOGIN_OR_CONSENT",
                label = "Login ou consentimento",
                summary = buildSummary(
                    base = "O app pede login, consentimento ou permissão antes de seguir.",
                    evidence = permissionEvidence,
                ),
                contextRelevant = false,
            )
        }

        val relevantEvidence = matchingEvidence(
            capturedTexts,
            relevantContextKeywords(providerKey),
        )
        if (relevantEvidence.isNotEmpty()) {
            return DriverSemanticStateSnapshot(
                code = "RELEVANT_CONTEXT",
                label = "Contexto relevante",
                summary = buildSummary(
                    base = "Há sinais locais de contexto relevante para a próxima fase do módulo.",
                    evidence = relevantEvidence,
                ),
                contextRelevant = true,
            )
        }

        val waitingEvidence = matchingEvidence(
            capturedTexts,
            waitingKeywords(providerKey),
        )
        if (waitingEvidence.isNotEmpty()) {
            return DriverSemanticStateSnapshot(
                code = "WAITING",
                label = "Aguardando",
                summary = buildSummary(
                    base = "O app está aberto e aguardando novas corridas.",
                    evidence = waitingEvidence,
                ),
                contextRelevant = false,
            )
        }

        val homeEvidence = matchingEvidence(
            capturedTexts,
            homeKeywords(providerKey),
        )
        if (homeEvidence.isNotEmpty()) {
            return DriverSemanticStateSnapshot(
                code = "HOME",
                label = "Tela inicial",
                summary = buildSummary(
                    base = "O provider está em foco na tela principal, mas ainda sem contexto operacional útil.",
                    evidence = homeEvidence,
                ),
                contextRelevant = false,
            )
        }

        return DriverSemanticStateSnapshot(
            code = "INSUFFICIENT_CONTEXT",
            label = "Contexto insuficiente",
            summary = buildSummary(
                base = "O provider está em foco, mas a captura local ainda é insuficiente.",
                evidence = capturedTexts.take(2),
            ),
            contextRelevant = false,
        )
    }

    private fun matchingEvidence(
        texts: List<String>,
        keywords: List<String>,
    ): List<String> {
        val evidence = linkedSetOf<String>()
        texts.forEach { text ->
            val normalized = text.lowercase(Locale.ROOT)
            if (keywords.any { keyword -> normalized.contains(keyword) }) {
                evidence += text
            }
        }
        return evidence
            .sortedWith(
                compareByDescending<String> { evidencePriority(it) }
                    .thenBy { it.length },
            )
            .take(2)
    }

    private fun buildSummary(
        base: String,
        evidence: List<String>,
    ): String {
        if (evidence.isEmpty()) {
            return base
        }
        val excerpts = evidence.joinToString(separator = "; ") { text ->
            "\"${text.take(80)}${if (text.length > 80) "…" else ""}\""
        }
        return "$base Sinais: $excerpts."
    }

    private fun evidencePriority(text: String): Int {
        val normalized = text.lowercase(Locale.ROOT)
        var score = 0
        if (normalized.contains("r$")) {
            score += 4
        }
        if (
            normalized.contains("alta demanda") ||
            normalized.contains("oportunidades") ||
            normalized.contains("sempre permitir") ||
            normalized.contains("configure as permissões") ||
            normalized.contains("configure as permissoes") ||
            normalized.contains("aceitar") ||
            normalized.contains("online")
        ) {
            score += 3
        }
        if (
            normalized.contains("tudo pronto para fazer entregas") ||
            normalized.contains("página inicial") ||
            normalized.contains("pagina inicial")
        ) {
            score += 2
        }
        if (text.length <= 48) {
            score += 1
        }
        return score
    }

    private fun permissionOrConsentKeywords(providerKey: String): List<String> {
        return when (providerKey) {
            "UBER_DRIVER" -> listOf(
                "faça login",
                "login",
                "permiss",
                "permitir",
                "localização",
                "localizacao",
                "modo de gerenciamento",
                "você já se conectou",
                "sempre permitir",
            )
            "APP99_DRIVER" -> listOf(
                "configure as permissões de localização",
                "configure as permissoes de localizacao",
                "sempre permitir",
                "política",
                "politica",
                "privacidade",
                "concordo",
                "termos",
                "permitir",
                "permiss",
                "entrar",
                "login",
            )
            else -> listOf("login", "concordo", "permitir", "permiss", "privacidade")
        }
    }

    private fun waitingKeywords(providerKey: String): List<String> {
        return when (providerKey) {
            "UBER_DRIVER" -> listOf(
                "você está online",
                "voce esta online",
                "online",
                "procurando",
                "aguardando",
                "novas corridas",
            )
            "APP99_DRIVER" -> listOf(
                "você está online",
                "voce esta online",
                "online",
                "procurando",
                "aguardando",
                "disponível",
                "disponivel",
            )
            else -> listOf("online", "procurando", "aguardando")
        }
    }

    private fun relevantContextKeywords(providerKey: String): List<String> {
        return when (providerKey) {
            "UBER_DRIVER", "APP99_DRIVER" -> listOf(
                "alta demanda",
                "demanda está alta",
                "demanda esta alta",
                "tempo de espera baixo",
                "oportunidades",
                "+r$",
                "r$ ",
                "corrida",
                "viagem",
                "solicitação",
                "solicitacao",
                "aceitar",
                "oferta",
                "embarque",
                "destino",
                "r$",
            )
            else -> listOf("corrida", "aceitar", "oferta", "r$")
        }
    }

    private fun homeKeywords(providerKey: String): List<String> {
        return when (providerKey) {
            "UBER_DRIVER" -> listOf(
                "tudo pronto para fazer entregas",
                "ficar online",
                "página inicial",
                "pagina inicial",
                "ganhos",
                "mensagens",
                "menu",
                "uber driver",
                "carbonactivity",
            )
            "APP99_DRIVER" -> listOf(
                "99 motorista",
                "início",
                "inicio",
                "tela inicial",
                "startactivity",
            )
            else -> listOf("início", "inicio", "tela inicial")
        }
    }

    private fun commandBlockReason(
        currentContext: DriverCurrentContextSnapshot,
        targetProviderKey: String?,
    ): String {
        return when {
            !moduleOperationallyReady() -> "MODULE_NOT_READY"
            targetProviderKey == null -> "NO_PROVIDER_CONTEXT"
            !targetAppReady(targetProviderKey) -> "TARGET_APP_NOT_READY"
            currentContext.validity == "EXPIRED" -> "CONTEXT_TTL_EXPIRED"
            currentContext.validity == "INVALID" -> currentContext.invalidationReason ?: "NO_PROVIDER_CONTEXT"
            currentContext.validity == "INCOMPLETE" -> "CONTEXT_NOT_CAPTURED"
            else -> "COMMAND_BLOCKED"
        }
    }

    private fun reconcileAcceptCommand(now: Instant) {
        if (!acceptCommand.hasPendingOrReady) {
            return
        }
        val targetProviderKey = acceptCommand.targetProviderKey ?: run {
            acceptCommand = acceptCommand.invalidated("NO_PROVIDER_CONTEXT", now)
            return
        }
        val targetContext = contextForProvider(targetProviderKey, now)
        if (targetContext == null || !targetContext.isActionable) {
            acceptCommand = acceptCommand.invalidated(
                reason = targetContext?.invalidationReason ?: "NO_PROVIDER_CONTEXT",
                updatedAt = now,
            )
        }
    }

    private fun advanceAcceptCommandIfPossible(now: Instant) {
        if (acceptCommand.state != "PENDING_EXECUTOR") {
            return
        }
        val targetProviderKey = acceptCommand.targetProviderKey ?: return
        val currentContext = resolveCurrentContext(now)
        if (currentContext.providerKey == targetProviderKey &&
            currentContext.validity == "VALID"
        ) {
            acceptCommand = acceptCommand.executorReady(updatedAt = now)
        }
    }

    private fun contextForProvider(
        providerKey: String,
        now: Instant,
    ): DriverCurrentContextSnapshot? {
        val providerSnapshot = providerContextsByKey[providerKey] ?: return null
        return buildContextSnapshot(
            snapshot = providerSnapshot,
            inFocus = focusedProviderKey == providerKey,
            now = now,
            defaultInvalidationReason = if (focusedProviderKey == providerKey) {
                null
            } else {
                lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS"
            },
        )
    }

    private fun targetAppReady(providerKey: String): Boolean {
        return targetApps.firstOrNull { target -> target.key == providerKey }?.appReady == true
    }

    private fun moduleOperationallyReady(): Boolean {
        return accessibilityServiceDeclared &&
            accessibilityServiceEnabled &&
            canOpenAccessibilitySettings &&
            targetApps.any { target -> target.appReady }
    }
}
