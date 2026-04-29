package com.example.despesas_frontend.driver

import java.time.Duration
import java.time.Instant
import java.util.Locale

private data class DriverSemanticTracker(
    val committedState: DriverSemanticStateSnapshot,
    val lastCommittedAt: Instant,
    val pendingState: DriverSemanticStateSnapshot? = null,
    val pendingSince: Instant? = null,
)

private data class DriverObservedContextEvent(
    val capturedAt: Instant,
    val texts: List<String>,
)

internal data class DriverOfferCandidateWindow(
    val providerKey: String,
    val providerLabel: String,
    val packageName: String,
    val texts: List<String>,
    val startedAt: Instant,
    val lastUpdatedAt: Instant,
)

object DriverStateManager {
    private const val CONTEXT_TTL_SECONDS = 15L
    private const val OFFER_RETENTION_SECONDS = 18L
    private const val OFFER_CANDIDATE_WINDOW_SECONDS = 3L
    private const val SEMANTIC_STABILITY_MILLIS = 1500L
    private const val SIGNAL_AGGREGATION_MILLIS = 8000L

    private val ONLINE_SIGNALS = listOf(
        "tudo pronto para fazer entregas",
    )
    private val ACTIVE_ONLINE_SIGNALS = listOf(
        "procurando viagens",
        "não é possível ficar offline",
        "nao e possivel ficar offline",
    )
    private val IDLE_HOME_SIGNALS = listOf(
        "página inicial",
        "pagina inicial",
        "ganhos",
        "mensagens",
        "menu",
        "descubra",
    )
    private val HIGH_DEMAND_SIGNALS = listOf(
        "alta demanda",
        "mais usuários do que o normal",
        "mais usuarios do que o normal",
    )
    private val OFFLINE_SIGNALS = listOf(
        "ficar online",
    )
    private val UNKNOWN_SIGNALS = listOf(
        "descubra as oportunidades",
        "veja quais são os melhores horários e regiões para aceitar solicitações hoje",
        "veja quais sao os melhores horarios e regioes para aceitar solicitacoes hoje",
        "horários e regiões",
        "horarios e regioes",
    )
    private val POSSIBLE_OPPORTUNITY_SIGNALS = listOf(
        "embarque",
        "destino",
        "corrida",
        "viagem",
        "oferta",
        "nova solicitação",
        "nova solicitacao",
        "solicitação recebida",
        "solicitacao recebida",
        "novo pedido",
        "aceitar corrida",
        "aceitar viagem",
        "solicitação",
        "solicitacao",
    )
    private val OFFER_ACTION_SIGNALS = listOf(
        "aceitar",
        "ver oferta",
        "nova solicitação",
        "nova solicitacao",
        "embarque",
        "destino",
        "passageiro",
        "corrida",
        "viagem",
    )
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
    private val providerSemanticTrackersByKey = linkedMapOf<String, DriverSemanticTracker>()
    private val providerObservedEventsByKey = linkedMapOf<String, MutableList<DriverObservedContextEvent>>()

    private var focusedProviderKey: String? = null
    private var focusedProviderLabel: String? = null
    private var focusedPackageName: String? = null
    private var lastInvalidationReason: String? = "NO_CONTEXT"

    private var acceptCommand = DriverAcceptCommandSnapshot.idle()
    private var lastOfferSnapshot: DriverOfferSnapshot? = null
    private var offerCandidateWindow: DriverOfferCandidateWindow? = null

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
        providerSemanticTrackersByKey.clear()
        providerObservedEventsByKey.clear()
        focusedProviderKey = null
        focusedProviderLabel = null
        focusedPackageName = null
        lastInvalidationReason = "NO_CONTEXT"
        acceptCommand = DriverAcceptCommandSnapshot.idle()
        lastOfferSnapshot = null
        offerCandidateWindow = null
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
        recordProviderEventAt(
            providerKey = providerKey,
            providerLabel = providerLabel,
            packageName = packageName,
            eventType = eventType,
            texts = texts,
            capturedAt = Instant.now(),
        )
    }

    @Synchronized
    fun recordOfferSnapshot(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        rawTexts: List<String>,
        detectedSignals: List<String>,
    ) {
        recordOfferSnapshotAt(
            providerKey = providerKey,
            providerLabel = providerLabel,
            packageName = packageName,
            rawTexts = rawTexts,
            detectedSignals = detectedSignals,
            capturedAt = Instant.now(),
        )
    }

    @Synchronized
    fun recordOfferSnapshotAt(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        rawTexts: List<String>,
        detectedSignals: List<String>,
        capturedAt: Instant,
    ) {
        val assessment = DriverOfferEventDetector.assessOffer(rawTexts)
        if (!assessment.isActionable) {
            DriverOfferTraceLogger.d(
                "recordOfferSnapshot skipped provider=$providerKey classification=${assessment.classification} " +
                    "missing=${assessment.missingRequirements.joinToString(" | ")}",
            )
            return
        }
        val snapshot = DriverOfferSnapshot(
            timestamp = capturedAt.toString(),
            providerKey = providerKey,
            providerLabel = providerLabel,
            packageName = packageName,
            rawTexts = rawTexts.distinct().take(12),
            detectedSignals = assessment.detectedSignals,
            summary = assessment.summary,
            confidence = assessment.confidence,
            classification = assessment.classification,
            isActionable = assessment.isActionable,
            missingRequirements = assessment.missingRequirements,
            structuredOffer = UberOfferParser.parse(
                providerKey = providerKey,
                classification = assessment.classification,
                isActionable = assessment.isActionable,
                texts = rawTexts,
                parsedAt = capturedAt,
            ),
        )
        lastOfferSnapshot = snapshot
        offerCandidateWindow = null
        DriverOfferTraceLogger.d(
            "recordOfferSnapshot provider=$providerKey ts=${snapshot.timestamp} " +
                "classification=${snapshot.classification} " +
                "signals=${snapshot.detectedSignals.joinToString(" | ")} ttl=${OFFER_RETENTION_SECONDS}s",
        )
    }

    @Synchronized
    fun mergeOfferCandidateTextsAt(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        texts: List<String>,
        capturedAt: Instant,
    ): List<String> {
        val existing = offerCandidateWindow?.takeIf { candidate ->
            candidate.providerKey == providerKey &&
                candidate.packageName == packageName &&
                Duration.between(candidate.lastUpdatedAt, capturedAt).seconds <= OFFER_CANDIDATE_WINDOW_SECONDS
        }
        val merged = linkedSetOf<String>()
        existing?.texts?.forEach { merged += it }
        texts.forEach { merged += it }
        offerCandidateWindow = DriverOfferCandidateWindow(
            providerKey = providerKey,
            providerLabel = providerLabel,
            packageName = packageName,
            texts = merged.take(40),
            startedAt = existing?.startedAt ?: capturedAt,
            lastUpdatedAt = capturedAt,
        )
        DriverOfferTraceLogger.d(
            "offerCandidate provider=$providerKey size=${offerCandidateWindow?.texts?.size ?: 0} " +
                "age=${Duration.between(offerCandidateWindow?.startedAt ?: capturedAt, capturedAt).toMillis()}ms",
        )
        return offerCandidateWindow?.texts ?: texts
    }

    @Synchronized
    fun recordProviderEventAt(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        eventType: String,
        texts: List<String>,
        capturedAt: Instant,
    ) {
        val previousProviderKey = focusedProviderKey
        focusedProviderKey = providerKey
        focusedProviderLabel = providerLabel
        focusedPackageName = packageName
        lastInvalidationReason = null
        invalidateRetainedOfferForDifferentProvider(providerKey)

        if (texts.isNotEmpty()) {
            val aggregatedTexts = mergeObservedTexts(
                providerKey = providerKey,
                texts = texts,
                capturedAt = capturedAt,
            )
            val semanticState = resolveStableSemanticState(
                providerKey = providerKey,
                texts = aggregatedTexts,
                now = capturedAt,
            )
            providerContextsByKey[providerKey] = DriverProviderContextSnapshot(
                providerKey = providerKey,
                label = providerLabel,
                packageName = packageName,
                eventType = eventType,
                capturedAt = capturedAt.toString(),
                texts = aggregatedTexts,
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
                updatedAt = capturedAt,
            )
        }

        advanceAcceptCommandIfPossible(capturedAt)
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
        DriverOfferTraceLogger.d("providerOutOfFocus package=$packageName")
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

    @Synchronized
    fun snapshotAt(now: Instant): DriverModuleNativeSnapshot {
        return buildSnapshot(now)
    }

    private fun buildSnapshot(now: Instant): DriverModuleNativeSnapshot {
        reconcileAcceptCommand(now)
        val currentContext = resolveCurrentContext(now)
        val recentOffer = resolveRecentOffer(now)
        val structuredOffer = resolveStructuredOffer(
            currentContext = currentContext,
            recentOffer = recentOffer,
            now = now,
        )
        val offerSignal = structuredOffer?.let {
            UberOfferSignalEvaluator.evaluate(
                offer = it,
                computedAt = now,
            )
        }
        DriverOfferTraceLogger.d(
            "snapshot semantic=${currentContext.semanticState.code} " +
                "lastOfferDetected=${recentOffer != null} " +
                "offerAgeMs=${recentOffer?.let { Duration.between(Instant.parse(it.timestamp), now).toMillis() }} " +
                "signalColor=${offerSignal?.color}",
        )
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
            lastOfferDetected = recentOffer != null,
            lastOfferAgeMs = recentOffer?.let { offer ->
                Duration.between(Instant.parse(offer.timestamp), now).toMillis()
            },
            lastOfferSummary = recentOffer?.summary,
            lastOfferSignals = recentOffer?.detectedSignals ?: emptyList(),
            lastOfferClassification = recentOffer?.classification,
            lastOfferActionable = recentOffer?.isActionable ?: false,
            lastOfferMissingRequirements = recentOffer?.missingRequirements ?: emptyList(),
            structuredOfferPresent = structuredOffer != null,
            structuredOffer = structuredOffer,
            offerClassification = structuredOffer?.classification,
            offerActionable = structuredOffer?.isActionable ?: false,
            offerMissingFields = structuredOffer?.missingFields ?: emptyList(),
            offerParsingConfidence = structuredOffer?.confidence,
            offerSignalPresent = offerSignal != null,
            offerSignal = offerSignal,
            offerSignalColor = offerSignal?.color,
            offerSignalReason = offerSignal?.reason,
            offerSignalWarnings = offerSignal?.warnings ?: emptyList(),
            farePerKmText = offerSignal?.farePerKmText,
            farePerMinuteText = offerSignal?.farePerMinuteText,
            estimatedTotalDistanceText = offerSignal?.estimatedTotalDistanceText,
            estimatedTotalDurationText = offerSignal?.estimatedTotalDurationText,
            signalRuleVersion = offerSignal?.ruleVersion,
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

        if (currentContext.validity == "EXPIRED" || currentContext.validity == "INVALID") {
            return DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = currentContext.invalidationReason ?: "NO_CONTEXT",
            )
        }

        return when (currentContext.semanticState.code) {
            "ONLINE_HIGH_DEMAND", "HOME_ONLINE" -> DriverOperationalSignalSnapshot(
                color = "GREEN",
                label = "Verde",
                reason = currentContext.semanticState.code,
            )
            "ACTIONABLE_OFFER" -> DriverOperationalSignalSnapshot(
                color = if (currentContext.semanticState.confidence == "HIGH") "GREEN" else "YELLOW",
                label = if (currentContext.semanticState.confidence == "HIGH") "Verde" else "Amarelo",
                reason = currentContext.semanticState.code,
            )
            "OFFER_CANDIDATE", "OFFER_EXPIRED_OR_MISSED" -> DriverOperationalSignalSnapshot(
                color = "YELLOW",
                label = "Amarelo",
                reason = currentContext.semanticState.code,
            )
            "OFFLINE", "NO_ACTIVE_PROVIDER" -> DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = currentContext.semanticState.code,
            )
            else -> DriverOperationalSignalSnapshot(
                color = "YELLOW",
                label = "Amarelo",
                reason = currentContext.semanticState.code,
            )
        }
    }

    private fun resolveCurrentContext(now: Instant): DriverCurrentContextSnapshot {
        val recentOffer = resolveRecentOffer(now)
        val focusedProviderKey = focusedProviderKey
        val focusedProviderLabel = focusedProviderLabel
        val focusedPackageName = focusedPackageName

        if (focusedProviderKey != null &&
            focusedProviderLabel != null &&
            focusedPackageName != null
        ) {
            if (recentOffer != null && recentOffer.providerKey == focusedProviderKey) {
                return retainedOfferContext(
                    offer = recentOffer,
                    inFocus = true,
                    invalidationReason = null,
                )
            }
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
                    semanticState = incompleteSemanticState(
                        base = "O provider está em foco, mas a captura local ainda é insuficiente.",
                        evidence = emptyList(),
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
            if (recentOffer != null && recentOffer.providerKey == latestContext.providerKey) {
                return retainedOfferContext(
                    offer = recentOffer,
                    inFocus = false,
                    invalidationReason = lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS",
                )
            }
            return buildContextSnapshot(
                snapshot = latestContext,
                inFocus = false,
                now = now,
                defaultInvalidationReason = lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS",
            )
        }

        if (recentOffer != null) {
            return retainedOfferContext(
                offer = recentOffer,
                inFocus = false,
                invalidationReason = "PROVIDER_OUT_OF_FOCUS",
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
            semanticState = noActiveProviderSemanticState(),
        )
    }

    private fun buildContextSnapshot(
        snapshot: DriverProviderContextSnapshot,
        inFocus: Boolean,
        now: Instant,
        defaultInvalidationReason: String?,
    ): DriverCurrentContextSnapshot {
        val recentOffer = resolveRecentOffer(now)
        if (recentOffer != null && recentOffer.providerKey == snapshot.providerKey) {
            return retainedOfferContext(
                offer = recentOffer,
                inFocus = inFocus,
                invalidationReason = if (inFocus) null else defaultInvalidationReason,
            )
        }
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
        val semanticState = when {
            expired -> outOfFocusSemanticState(
                base = "O último contexto do Uber expirou e precisa ser capturado de novo.",
                evidence = snapshot.semanticState.detectedSignals,
            )
            else -> snapshot.semanticState
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
            semanticState = semanticState,
        )
    }

    private fun retainedOfferContext(
        offer: DriverOfferSnapshot,
        inFocus: Boolean,
        invalidationReason: String?,
    ): DriverCurrentContextSnapshot {
        val validUntil = Instant.parse(offer.timestamp).plusSeconds(OFFER_RETENTION_SECONDS)
        return DriverCurrentContextSnapshot(
            providerKey = offer.providerKey,
            label = offer.providerLabel,
            packageName = offer.packageName,
            eventType = "OFFER_SNAPSHOT_RETAINED",
            capturedAt = offer.timestamp,
            texts = offer.rawTexts,
            inFocus = inFocus,
            validity = if (inFocus) "VALID" else "STALE",
            validUntil = validUntil.toString(),
            invalidationReason = if (inFocus) null else invalidationReason,
            semanticState = offerSemanticState(offer),
        )
    }

    private fun resolveStructuredOffer(
        currentContext: DriverCurrentContextSnapshot,
        recentOffer: DriverOfferSnapshot?,
        now: Instant,
    ): DriverStructuredOffer? {
        recentOffer?.structuredOffer?.let { return it }

        val classification = currentContext.semanticState.code
        if (classification != "ACTIONABLE_OFFER" && classification != "OFFER_CANDIDATE") {
            return null
        }

        if (currentContext.texts.isEmpty()) {
            return null
        }

        val parsedAt = currentContext.capturedAt
            .takeIf { it.isNotBlank() }
            ?.let(Instant::parse)
            ?: now

        return UberOfferParser.parse(
            providerKey = currentContext.providerKey,
            classification = classification,
            isActionable = classification == "ACTIONABLE_OFFER",
            texts = currentContext.texts,
            parsedAt = parsedAt,
        )
    }

    private fun resolveStableSemanticState(
        providerKey: String,
        texts: List<String>,
        now: Instant,
    ): DriverSemanticStateSnapshot {
        val candidateState = detectSemanticState(
            providerKey = providerKey,
            texts = texts,
        )
        val existingTracker = providerSemanticTrackersByKey[providerKey]

        if (existingTracker == null) {
            providerSemanticTrackersByKey[providerKey] = DriverSemanticTracker(
                committedState = candidateState,
                lastCommittedAt = now,
            )
            return candidateState
        }

        if (existingTracker.committedState.code == candidateState.code) {
            val refreshedCommittedState = existingTracker.committedState.copy(
                summary = candidateState.summary,
                contextRelevant = candidateState.contextRelevant,
                confidence = candidateState.confidence,
                detectedSignals = candidateState.detectedSignals,
            )
            providerSemanticTrackersByKey[providerKey] = existingTracker.copy(
                committedState = refreshedCommittedState,
                lastCommittedAt = now,
                pendingState = null,
                pendingSince = null,
            )
            return refreshedCommittedState
        }

        if (existingTracker.pendingState?.code == candidateState.code &&
            existingTracker.pendingSince != null &&
            Duration.between(existingTracker.pendingSince, now).toMillis() >= SEMANTIC_STABILITY_MILLIS
        ) {
            providerSemanticTrackersByKey[providerKey] = DriverSemanticTracker(
                committedState = candidateState,
                lastCommittedAt = now,
            )
            return candidateState
        }

        providerSemanticTrackersByKey[providerKey] = existingTracker.copy(
            pendingState = candidateState,
            pendingSince = now,
        )
        return existingTracker.committedState
    }

    private fun mergeObservedTexts(
        providerKey: String,
        texts: List<String>,
        capturedAt: Instant,
    ): List<String> {
        val events = providerObservedEventsByKey.getOrPut(providerKey) { mutableListOf() }
        events += DriverObservedContextEvent(
            capturedAt = capturedAt,
            texts = texts,
        )
        val windowStart = capturedAt.minusMillis(SIGNAL_AGGREGATION_MILLIS)
        events.removeAll { event -> event.capturedAt.isBefore(windowStart) }
        return events
            .asSequence()
            .sortedByDescending { event -> event.capturedAt }
            .flatMap { event -> event.texts.asSequence() }
            .map { text -> text.trim() }
            .filter { text -> text.isNotBlank() }
            .distinct()
            .take(12)
            .toList()
    }

    private fun detectSemanticState(
        providerKey: String,
        texts: List<String>,
    ): DriverSemanticStateSnapshot {
        if (providerKey.isBlank()) {
            return noActiveProviderSemanticState()
        }

        val capturedTexts = texts
            .map { text -> text.trim() }
            .filter { text -> text.isNotBlank() }

        if (capturedTexts.isEmpty()) {
            return incompleteSemanticState(
                base = "O provider está em foco, mas a captura local ainda é insuficiente.",
                evidence = emptyList(),
            )
        }

        return if (providerKey == "UBER_DRIVER") {
            detectUberSemanticState(capturedTexts)
        } else {
            detectLegacySemanticState(providerKey, capturedTexts)
        }
    }

    private fun detectUberSemanticState(texts: List<String>): DriverSemanticStateSnapshot {
        val offerAssessment = DriverOfferEventDetector.assessOffer(texts)
        val offlineEvidence = matchingEvidence(texts, OFFLINE_SIGNALS)
        val onlineEvidence = matchingEvidence(texts, ONLINE_SIGNALS)
        val activeOnlineEvidence = matchingEvidence(texts, ACTIVE_ONLINE_SIGNALS)
        val highDemandEvidence = matchingEvidence(texts, HIGH_DEMAND_SIGNALS)
        val idleHomeEvidence = matchingEvidence(texts, IDLE_HOME_SIGNALS)
        val unknownEvidence = matchingEvidence(texts, UNKNOWN_SIGNALS)
        val etaEvidence = texts.filter { text ->
            text.lowercase(Locale.ROOT).matches(Regex("""\d+\s*-\s*\d+\s*min"""))
        }

        if (offerAssessment.classification == "ACTIONABLE_OFFER") {
            return semanticState(
                code = "ACTIONABLE_OFFER",
                label = "Oferta acionável",
                base = "O Uber mostra uma oferta completa e acionável.",
                contextRelevant = true,
                confidence = offerAssessment.confidence,
                evidence = offerAssessment.detectedSignals,
                missingRequirements = offerAssessment.missingRequirements,
            )
        }

        if (offerAssessment.classification == "OFFER_CANDIDATE") {
            return semanticState(
                code = "OFFER_CANDIDATE",
                label = "Oferta candidata",
                base = "O Uber mostra quase toda a oferta, mas ainda falta um requisito crítico.",
                contextRelevant = false,
                confidence = offerAssessment.confidence,
                evidence = offerAssessment.detectedSignals,
                missingRequirements = offerAssessment.missingRequirements,
            )
        }

        if (offerAssessment.classification == "OFFER_EXPIRED_OR_MISSED") {
            return semanticState(
                code = "OFFER_EXPIRED_OR_MISSED",
                label = "Oferta expirada ou perdida",
                base = "Houve sinal real de evento no Uber, mas o cartão completo já não estava mais visível.",
                contextRelevant = false,
                confidence = offerAssessment.confidence,
                evidence = offerAssessment.detectedSignals,
                missingRequirements = offerAssessment.missingRequirements,
            )
        }

        if (activeOnlineEvidence.isNotEmpty() && highDemandEvidence.isNotEmpty()) {
            val evidence = (activeOnlineEvidence + highDemandEvidence + etaEvidence).distinct().take(4)
            return semanticState(
                code = "HOME_ONLINE",
                label = "Online aguardando corrida",
                base = "O motorista está online, aguardando corridas, e o Uber indica alta demanda sem oferta acionável visível.",
                contextRelevant = false,
                confidence = "HIGH",
                evidence = evidence,
            )
        }

        if (activeOnlineEvidence.isNotEmpty()) {
            val evidence = (activeOnlineEvidence + etaEvidence + onlineEvidence).distinct().take(4)
            return semanticState(
                code = "HOME_ONLINE",
                label = "Online aguardando corrida",
                base = "O motorista está online e o Uber já está procurando viagens.",
                contextRelevant = false,
                confidence = "HIGH",
                evidence = evidence,
            )
        }

        if (offlineEvidence.isNotEmpty()) {
            return semanticState(
                code = "OFFLINE",
                label = "Offline",
                base = "O Uber mostra o botão para ficar online e o motorista ainda está offline.",
                contextRelevant = false,
                confidence = "HIGH",
                evidence = (offlineEvidence + onlineEvidence.take(1)).distinct().take(4),
            )
        }

        if (onlineEvidence.isNotEmpty()) {
            val evidence = (onlineEvidence + idleHomeEvidence).distinct().take(4)
            return semanticState(
                code = "HOME_ONLINE",
                label = "Online aguardando corrida",
                base = "O motorista está online e aguardando corrida no Uber.",
                contextRelevant = false,
                confidence = if (onlineEvidence.size >= 2 || idleHomeEvidence.isNotEmpty()) "HIGH" else "MEDIUM",
                evidence = evidence,
            )
        }

        if (idleHomeEvidence.isNotEmpty()) {
            return semanticState(
                code = "HOME_ONLINE",
                label = "Online aguardando corrida",
                base = "O Uber está na home e sem oferta acionável visível no momento.",
                contextRelevant = false,
                confidence = if (unknownEvidence.isNotEmpty()) "MEDIUM" else "LOW",
                evidence = (idleHomeEvidence + unknownEvidence + etaEvidence).distinct().take(4),
            )
        }

        return incompleteSemanticState(
            base = "O Uber está em foco, mas a captura local ainda não sustenta um estado confiável.",
            evidence = texts.take(3),
        )
    }

    private fun offerSemanticState(offer: DriverOfferSnapshot): DriverSemanticStateSnapshot {
        return DriverSemanticStateSnapshot(
            code = offer.classification,
            label = "Oferta acionável",
            summary = offer.summary,
            contextRelevant = offer.isActionable,
            confidence = offer.confidence,
            detectedSignals = offer.detectedSignals,
            missingRequirements = offer.missingRequirements,
        )
    }

    private fun detectLegacySemanticState(
        providerKey: String,
        capturedTexts: List<String>,
    ): DriverSemanticStateSnapshot {
        val permissionEvidence = matchingEvidence(
            capturedTexts,
            permissionOrConsentKeywords(providerKey),
        )
        if (permissionEvidence.isNotEmpty()) {
            return semanticState(
                code = "LOGIN_OR_CONSENT",
                label = "Login ou consentimento",
                base = "O app pede login, consentimento ou permissão antes de seguir.",
                contextRelevant = false,
                confidence = "HIGH",
                evidence = permissionEvidence,
            )
        }

        val relevantEvidence = matchingEvidence(
            capturedTexts,
            relevantContextKeywords(providerKey),
        )
        if (relevantEvidence.isNotEmpty()) {
            return semanticState(
                code = "RELEVANT_CONTEXT",
                label = "Contexto relevante",
                base = "Há sinais locais de contexto relevante para a próxima fase do módulo.",
                contextRelevant = true,
                confidence = "MEDIUM",
                evidence = relevantEvidence,
            )
        }

        val waitingEvidence = matchingEvidence(
            capturedTexts,
            waitingKeywords(providerKey),
        )
        if (waitingEvidence.isNotEmpty()) {
            return semanticState(
                code = "WAITING",
                label = "Aguardando",
                base = "O app está aberto e aguardando novas corridas.",
                contextRelevant = false,
                confidence = "MEDIUM",
                evidence = waitingEvidence,
            )
        }

        val homeEvidence = matchingEvidence(
            capturedTexts,
            homeKeywords(providerKey),
        )
        if (homeEvidence.isNotEmpty()) {
            return semanticState(
                code = "HOME",
                label = "Tela inicial",
                base = "O provider está em foco na tela principal, mas ainda sem contexto operacional útil.",
                contextRelevant = false,
                confidence = "LOW",
                evidence = homeEvidence,
            )
        }

        return incompleteSemanticState(
            base = "O provider está em foco, mas a captura local ainda é insuficiente.",
            evidence = capturedTexts.take(2),
        )
    }

    private fun noActiveProviderSemanticState(): DriverSemanticStateSnapshot {
        return DriverSemanticStateSnapshot(
            code = "NO_ACTIVE_PROVIDER",
            label = "Sem provider ativo",
            summary = "Abra o Uber Driver para iniciar a leitura local.",
            contextRelevant = false,
            confidence = "LOW",
            detectedSignals = emptyList(),
        )
    }

    private fun outOfFocusSemanticState(
        base: String,
        evidence: List<String>,
    ): DriverSemanticStateSnapshot {
        return DriverSemanticStateSnapshot(
            code = "OUT_OF_FOCUS",
            label = "Fora de foco",
            summary = buildSummary(base, evidence),
            contextRelevant = false,
            confidence = "LOW",
            detectedSignals = evidence,
        )
    }

    private fun incompleteSemanticState(
        base: String,
        evidence: List<String>,
    ): DriverSemanticStateSnapshot {
        return DriverSemanticStateSnapshot(
            code = "INSUFFICIENT_CONTEXT",
            label = "Contexto insuficiente",
            summary = buildSummary(base, evidence),
            contextRelevant = false,
            confidence = if (evidence.isEmpty()) "LOW" else "MEDIUM",
            detectedSignals = evidence,
            missingRequirements = emptyList(),
        )
    }

    private fun semanticState(
        code: String,
        label: String,
        base: String,
        contextRelevant: Boolean,
        confidence: String,
        evidence: List<String>,
        missingRequirements: List<String> = emptyList(),
    ): DriverSemanticStateSnapshot {
        return DriverSemanticStateSnapshot(
            code = code,
            label = label,
            summary = buildSummary(base, evidence),
            contextRelevant = contextRelevant,
            confidence = confidence,
            detectedSignals = evidence,
            missingRequirements = missingRequirements,
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
            .take(4)
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

    private fun resolveRecentOffer(now: Instant): DriverOfferSnapshot? {
        val offer = lastOfferSnapshot ?: return null
        val age = Duration.between(Instant.parse(offer.timestamp), now)
        if (age.isNegative || age.seconds > OFFER_RETENTION_SECONDS) {
            if (!age.isNegative) {
                lastOfferSnapshot = null
                DriverOfferTraceLogger.d(
                    "offerExpired provider=${offer.providerKey} ageMs=${age.toMillis()}",
                )
            }
            return null
        }
        return offer
    }

    private fun invalidateRetainedOfferForDifferentProvider(providerKey: String) {
        val offer = lastOfferSnapshot ?: return
        if (offer.providerKey != providerKey) {
            lastOfferSnapshot = null
            DriverOfferTraceLogger.d(
                "offerInvalidated providerChange old=${offer.providerKey} new=$providerKey",
            )
        }
        val candidate = offerCandidateWindow ?: return
        if (candidate.providerKey != providerKey) {
            offerCandidateWindow = null
            DriverOfferTraceLogger.d(
                "offerCandidateInvalidated providerChange old=${candidate.providerKey} new=$providerKey",
            )
        }
    }

    private fun evidencePriority(text: String): Int {
        val normalized = text.lowercase(Locale.ROOT)
        var score = 0
        if (normalized.contains("r$") || DriverOfferEventDetector.containsPositiveMoneySignal(text)) {
            score += 4
        }
        if (
            normalized.contains("alta demanda") ||
            normalized.contains("oportunidades") ||
            normalized.contains("aceitar") ||
            normalized.contains("sempre permitir") ||
            normalized.contains("configure as permissões") ||
            normalized.contains("configure as permissoes")
        ) {
            score += 3
        }
        if (
            normalized.contains("tudo pronto para fazer entregas") ||
            normalized.contains("ficar online") ||
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
