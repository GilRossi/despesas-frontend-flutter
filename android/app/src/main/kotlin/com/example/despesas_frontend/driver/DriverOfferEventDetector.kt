package com.example.despesas_frontend.driver

import java.util.Locale

internal data class DriverOfferAssessment(
    val classification: String,
    val isActionable: Boolean,
    val detectedSignals: List<String>,
    val missingRequirements: List<String>,
    val confidence: String,
    val summary: String,
)

internal object DriverOfferEventDetector {
    private val POSITIVE_MONEY_PATTERN = Regex("""(^|\s)(\+?\s*)?r\$\s*\d+([.,]\d{2})?""")
    private val NEGATIVE_MONEY_PATTERN = Regex("""(^|\s)-\s*r\$\s*\d+([.,]\d{2})?""")
    private val HOME_ETA_PATTERN = Regex("""^\d+\s*-\s*\d+\s*min$""")
    private val ROUTE_METRICS_PATTERN = Regex("""\b\d+\s*(min|minutos)\s*\(\d+[.,]?\d*\s*km\)""")

    private val STRONG_CTA_SIGNALS = listOf(
        "selecionar",
        "aceitar corrida",
        "aceitar viagem",
    )
    private val PRODUCT_SIGNALS = listOf(
        "uberx",
        "comfort",
        "flash",
        "black",
        "moto",
    )
    private val ADDRESS_HINTS = listOf(
        "rua ",
        "avenida ",
        "av. ",
        "travessa ",
        "praia grande",
        "quietude",
        "ocian",
        "boqueirão",
        "boqueirao",
        "maracanã",
        "maracana",
        "nova mirim",
        "boqueirão",
        "santos",
    )
    private val ONLINE_HOME_SIGNALS = listOf(
        "você está online",
        "voce esta online",
        "procurando viagens",
        "não é possível ficar offline",
        "nao e possivel ficar offline",
        "página inicial",
        "pagina inicial",
        "pesquisar locais",
        "tendências de ganhos",
        "tendencias de ganhos",
        "ganhos",
        "mensagens",
        "menu",
    )
    private val EXPIRED_OR_MISSED_SIGNALS = listOf(
        "encontramos outro motorista parceiro para essa solicitação",
        "encontramos outro motorista parceiro para essa solicitacao",
    )

    fun assessOffer(texts: List<String>): DriverOfferAssessment {
        val capturedTexts = texts
            .map(String::trim)
            .filter(String::isNotBlank)
            .distinct()

        val positiveMoneySignals = capturedTexts.filter(::containsPositiveMoneySignal)
        val negativeMoneySignals = capturedTexts.filter(::containsNegativeMoneySignal)
        val ctaSignals = capturedTexts.filter(::containsStrongCtaSignal)
        val routeSignals = capturedTexts.filter(::containsRouteMetrics)
        val addressSignals = capturedTexts.filter(::containsAddressOrRegionSignal)
        val productSignals = capturedTexts.filter(::containsProductSignal)
        val expiredSignals = capturedTexts.filter(::containsExpiredOrMissedSignal)
        val homeSignals = capturedTexts.filter(::containsHomeOnlineSignal)
        val etaChipSignals = capturedTexts.filter(::containsHomeEtaChip)

        val hasActionableLocation = addressSignals.isNotEmpty() || productSignals.isNotEmpty()
        val missingRequirements = buildList {
            if (positiveMoneySignals.isEmpty()) add("valor_positivo")
            if (ctaSignals.isEmpty()) add("cta_forte")
            if (routeSignals.isEmpty()) add("tempo_distancia")
            if (!hasActionableLocation) add("local_ou_produto")
        }

        if (
            positiveMoneySignals.isNotEmpty() &&
            ctaSignals.isNotEmpty() &&
            routeSignals.isNotEmpty() &&
            hasActionableLocation
        ) {
            val evidence = prioritizedEvidence(
                positiveMoneySignals,
                ctaSignals,
                routeSignals,
                addressSignals,
                productSignals,
            )
            return DriverOfferAssessment(
                classification = "ACTIONABLE_OFFER",
                isActionable = true,
                detectedSignals = evidence,
                missingRequirements = emptyList(),
                confidence = "HIGH",
                summary = buildSummary(
                    base = "Oferta acionável do Uber detectada com valor, CTA e contexto de rota completos.",
                    evidence = evidence,
                    missingRequirements = emptyList(),
                ),
            )
        }

        if (
            positiveMoneySignals.isNotEmpty() &&
            routeSignals.isNotEmpty() &&
            hasActionableLocation
        ) {
            val evidence = prioritizedEvidence(
                positiveMoneySignals,
                ctaSignals,
                routeSignals,
                addressSignals,
                productSignals,
                expiredSignals,
            )
            return DriverOfferAssessment(
                classification = "OFFER_CANDIDATE",
                isActionable = false,
                detectedSignals = evidence,
                missingRequirements = missingRequirements,
                confidence = if (ctaSignals.isEmpty()) "HIGH" else "MEDIUM",
                summary = buildSummary(
                    base = "Há indício forte de oferta do Uber, mas ainda falta um requisito crítico para torná-la acionável.",
                    evidence = evidence,
                    missingRequirements = missingRequirements,
                ),
            )
        }

        if (
            negativeMoneySignals.isNotEmpty() &&
            etaChipSignals.isNotEmpty() &&
            homeSignals.isNotEmpty()
        ) {
            val evidence = prioritizedEvidence(
                negativeMoneySignals,
                homeSignals,
                etaChipSignals,
            )
            return DriverOfferAssessment(
                classification = "OFFER_EXPIRED_OR_MISSED",
                isActionable = false,
                detectedSignals = evidence,
                missingRequirements = listOf(
                    "valor_positivo",
                    "cta_forte",
                    "tempo_distancia_acionavel",
                    "local_ou_produto",
                ),
                confidence = "MEDIUM",
                summary = buildSummary(
                    base = "O Uber mostrou sinais de evento real, mas o cartão completo já não estava íntegro no snapshot.",
                    evidence = evidence,
                    missingRequirements = listOf("cartao_completo"),
                ),
            )
        }

        if (expiredSignals.isNotEmpty()) {
            val evidence = prioritizedEvidence(
                expiredSignals,
                positiveMoneySignals,
                routeSignals,
                addressSignals,
                productSignals,
            )
            return DriverOfferAssessment(
                classification = "OFFER_EXPIRED_OR_MISSED",
                isActionable = false,
                detectedSignals = evidence,
                missingRequirements = listOf("cta_forte"),
                confidence = "MEDIUM",
                summary = buildSummary(
                    base = "O evento real do Uber já voltou de estado e o cartão completo não permaneceu visível.",
                    evidence = evidence,
                    missingRequirements = listOf("cta_forte"),
                ),
            )
        }

        val homeEvidence = prioritizedEvidence(homeSignals, etaChipSignals)
        return DriverOfferAssessment(
            classification = "HOME_ONLINE",
            isActionable = false,
            detectedSignals = homeEvidence,
            missingRequirements = listOf(
                "valor_positivo",
                "cta_forte",
                "tempo_distancia",
                "local_ou_produto",
            ),
            confidence = if (homeEvidence.isNotEmpty()) "HIGH" else "LOW",
            summary = buildSummary(
                base = "O Uber está online e aguardando corridas, mas sem oferta acionável visível.",
                evidence = homeEvidence,
                missingRequirements = listOf("oferta_acionavel"),
            ),
        )
    }

    fun isPotentialOfferEvent(
        packageName: String,
        eventType: String,
        detectedSignals: List<String>,
    ): Boolean {
        if (!packageName.equals("com.ubercab.driver", ignoreCase = true)) {
            return false
        }
        if (
            eventType != "TYPE_WINDOW_CONTENT_CHANGED" &&
            eventType != "TYPE_WINDOW_STATE_CHANGED" &&
            eventType != "TYPE_WINDOWS_CHANGED"
        ) {
            return false
        }
        val hasPositiveMoneySignal = detectedSignals.any(::containsPositiveMoneySignal)
        val hasStrongCtaSignal = detectedSignals.any(::containsStrongCtaSignal)
        val hasRouteMetrics = detectedSignals.any(::containsRouteMetrics)
        val result = hasPositiveMoneySignal && hasStrongCtaSignal && hasRouteMetrics
        DriverOfferTraceLogger.d(
            "detector package=$packageName event=$eventType " +
                "signals=${detectedSignals.joinToString(" | ")} " +
                "money=$hasPositiveMoneySignal cta=$hasStrongCtaSignal route=$hasRouteMetrics result=$result",
        )
        return result
    }

    fun detectOfferSignals(texts: List<String>): List<String> {
        return assessOffer(texts).detectedSignals
    }

    internal fun containsPositiveMoneySignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return POSITIVE_MONEY_PATTERN.containsMatchIn(normalized) &&
            !NEGATIVE_MONEY_PATTERN.containsMatchIn(normalized)
    }

    internal fun containsNegativeMoneySignal(text: String): Boolean {
        return NEGATIVE_MONEY_PATTERN.containsMatchIn(normalizeSignalText(text))
    }

    private fun containsStrongCtaSignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return STRONG_CTA_SIGNALS.any { keyword -> normalized.contains(keyword) }
    }

    private fun containsRouteMetrics(text: String): Boolean {
        return ROUTE_METRICS_PATTERN.containsMatchIn(normalizeSignalText(text))
    }

    private fun containsAddressOrRegionSignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return ADDRESS_HINTS.any { keyword -> normalized.contains(keyword) }
    }

    private fun containsProductSignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return PRODUCT_SIGNALS.any { keyword -> normalized == keyword }
    }

    private fun containsExpiredOrMissedSignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return EXPIRED_OR_MISSED_SIGNALS.any { keyword -> normalized.contains(keyword) }
    }

    private fun containsHomeOnlineSignal(text: String): Boolean {
        val normalized = normalizeSignalText(text)
        return ONLINE_HOME_SIGNALS.any { keyword -> normalized.contains(keyword) }
    }

    private fun containsHomeEtaChip(text: String): Boolean {
        return HOME_ETA_PATTERN.matches(normalizeSignalText(text))
    }

    private fun prioritizedEvidence(vararg groups: List<String>): List<String> {
        val merged = linkedSetOf<String>()
        groups.forEach { group ->
            group.forEach { signal -> merged += signal }
        }
        return merged.take(8)
    }

    private fun buildSummary(
        base: String,
        evidence: List<String>,
        missingRequirements: List<String>,
    ): String {
        val evidenceBlock = if (evidence.isEmpty()) {
            ""
        } else {
            " Sinais: ${evidence.joinToString("; ") { "\"${it.take(80)}${if (it.length > 80) "…" else ""}\"" }}."
        }
        val missingBlock = if (missingRequirements.isEmpty()) {
            ""
        } else {
            " Faltando: ${missingRequirements.joinToString(", ")}."
        }
        return "$base$evidenceBlock$missingBlock".trim()
    }

    private fun normalizeSignalText(text: String): String {
        return text
            .lowercase(Locale.ROOT)
            .replace('\u00A0', ' ')
            .replace('\u2007', ' ')
            .replace('\u202F', ' ')
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}
