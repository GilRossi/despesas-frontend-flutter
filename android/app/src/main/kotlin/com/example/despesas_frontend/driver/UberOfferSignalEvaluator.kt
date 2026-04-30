package com.example.despesas_frontend.driver

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.util.Locale

data class DriverOfferSignal(
    val color: String,
    val label: String,
    val reason: String,
    val warnings: List<String>,
    val farePerKmText: String?,
    val farePerHourText: String?,
    val estimatedTotalDistanceKm: Double?,
    val estimatedTotalDurationMin: Int?,
    val estimatedTotalDistanceText: String?,
    val estimatedTotalDurationText: String?,
    val ruleVersion: String,
    val computedAt: String,
    val preferencesSource: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "color" to color,
            "label" to label,
            "reason" to reason,
            "warnings" to warnings,
            "farePerKmText" to farePerKmText,
            "farePerHourText" to farePerHourText,
            "estimatedTotalDistanceKm" to estimatedTotalDistanceKm,
            "estimatedTotalDurationMin" to estimatedTotalDurationMin,
            "estimatedTotalDistanceText" to estimatedTotalDistanceText,
            "estimatedTotalDurationText" to estimatedTotalDurationText,
            "ruleVersion" to ruleVersion,
            "computedAt" to computedAt,
            "preferencesSource" to preferencesSource,
        )
    }
}

internal object UberOfferSignalEvaluator {
    const val RULE_VERSION = "UBER_SIGNAL_V1_CONFIGURABLE"

    private val DISTANCE_PATTERN = Regex("""(\d+[.,]?\d*)\s*km""", RegexOption.IGNORE_CASE)
    private val DURATION_PATTERN = Regex("""(\d+)\s*(?:min|minutos)""", RegexOption.IGNORE_CASE)
    fun evaluate(
        offer: DriverStructuredOffer,
        preferences: DriverSignalPreferences,
        computedAt: Instant,
    ): DriverOfferSignal {
        val warnings = mutableListOf<String>()
        val metrics = parseMetrics(offer)
        val fareAmount = offer.fareAmountCents?.let(::centsToAmount)
        val distanceWarningThreshold = preferences.maxTotalDistanceKm.multiply(BigDecimal("0.80"))
        val durationWarningThreshold = maxOf(1, (preferences.maxTotalDurationMin * 0.60).toInt())

        if (fareAmount != null && fareAmount < preferences.minTotalFare) {
            warnings += "Valor total baixo."
        }
        if (metrics.totalDistanceKm != null && metrics.totalDistanceKm >= distanceWarningThreshold) {
            warnings += "Distância total perto do limite configurado."
        }
        if (metrics.totalDurationMin != null && metrics.totalDurationMin >= durationWarningThreshold) {
            warnings += "Tempo total perto do limite configurado."
        }

        if (!offer.isActionable) {
            warnings += offer.missingFields.map(::missingFieldLabel)
            return signal(
                color = "RED",
                label = "Vermelho",
                reason = when (offer.classification) {
                    "OFFER_CANDIDATE" -> "Oferta incompleta: falta requisito crítico para ação."
                    else -> "Oferta não acionável."
                },
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerHour = metrics.farePerHour,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                preferencesSource = preferences.source,
                computedAt = computedAt,
            )
        }

        if (fareAmount == null || metrics.totalDistanceKm == null || metrics.totalDurationMin == null ||
            metrics.farePerKm == null || metrics.farePerHour == null
        ) {
            warnings += "Dados insuficientes para decidir com segurança."
            return signal(
                color = "RED",
                label = "Vermelho",
                reason = "Farol indisponível por dados insuficientes.",
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerHour = metrics.farePerHour,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                preferencesSource = preferences.source,
                computedAt = computedAt,
            )
        }

        if (metrics.totalDistanceKm > preferences.maxTotalDistanceKm ||
            metrics.totalDurationMin > preferences.maxTotalDurationMin
        ) {
            warnings += "Oferta ultrapassa o limite configurado."
            return signal(
                color = "RED",
                label = "Vermelho",
                reason = "Distância ou tempo acima do limite configurado.",
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerHour = metrics.farePerHour,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                preferencesSource = preferences.source,
                computedAt = computedAt,
            )
        }

        if (metrics.farePerKm >= preferences.minGreenFarePerKm &&
            metrics.farePerHour >= preferences.minGreenFarePerHour &&
            fareAmount >= preferences.minTotalFare &&
            metrics.totalDistanceKm <= preferences.maxTotalDistanceKm &&
            metrics.totalDurationMin <= preferences.maxTotalDurationMin
        ) {
            return signal(
                color = "GREEN",
                label = "Verde",
                reason = "Oferta acima dos limites verdes configurados.",
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerHour = metrics.farePerHour,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                preferencesSource = preferences.source,
                computedAt = computedAt,
            )
        }

        if (metrics.farePerKm >= preferences.minYellowFarePerKm &&
            metrics.farePerHour >= preferences.minYellowFarePerHour
        ) {
            val reason = when {
                fareAmount < preferences.minTotalFare ->
                    "Oferta acionável, mas abaixo do valor mínimo configurado."
                metrics.farePerKm < preferences.minGreenFarePerKm ||
                    metrics.farePerHour < preferences.minGreenFarePerHour ->
                    "Oferta acionável, mas abaixo do patamar verde configurado."
                else -> "Oferta acionável com avisos, mas acima dos mínimos amarelos configurados."
            }
            return signal(
                color = "YELLOW",
                label = "Amarelo",
                reason = reason,
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerHour = metrics.farePerHour,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                preferencesSource = preferences.source,
                computedAt = computedAt,
            )
        }

        return signal(
            color = "RED",
            label = "Vermelho",
            reason = "Oferta abaixo dos mínimos amarelos configurados.",
            warnings = warnings.distinct(),
            farePerKm = metrics.farePerKm,
            farePerHour = metrics.farePerHour,
            totalDistanceKm = metrics.totalDistanceKm,
            totalDurationMin = metrics.totalDurationMin,
            preferencesSource = preferences.source,
            computedAt = computedAt,
        )
    }

    private fun signal(
        color: String,
        label: String,
        reason: String,
        warnings: List<String>,
        farePerKm: BigDecimal?,
        farePerHour: BigDecimal?,
        totalDistanceKm: BigDecimal?,
        totalDurationMin: Int?,
        preferencesSource: String,
        computedAt: Instant,
    ): DriverOfferSignal {
        return DriverOfferSignal(
            color = color,
            label = label,
            reason = reason,
            warnings = warnings,
            farePerKmText = farePerKm?.let { "R$ ${formatDecimal(it)}/km" },
            farePerHourText = farePerHour?.let { "R$ ${formatDecimal(it)}/h" },
            estimatedTotalDistanceKm = totalDistanceKm?.toDouble(),
            estimatedTotalDurationMin = totalDurationMin,
            estimatedTotalDistanceText = totalDistanceKm?.let { "${formatSingleDecimal(it)} km" },
            estimatedTotalDurationText = totalDurationMin?.let { "$it min" },
            ruleVersion = RULE_VERSION,
            computedAt = computedAt.toString(),
            preferencesSource = preferencesSource,
        )
    }

    private fun parseMetrics(offer: DriverStructuredOffer): ParsedOfferMetrics {
        val fareAmount = offer.fareAmountCents?.let(::centsToAmount)
        val pickupDistanceKm = parseDistanceKm(offer.pickupDistanceText)
        val tripDistanceKm = parseDistanceKm(offer.tripDistanceText)
        val pickupEtaMin = parseDurationMin(offer.pickupEtaText)
        val tripDurationMin = parseDurationMin(offer.tripDurationText)
        val totalDistanceKm = if (pickupDistanceKm != null && tripDistanceKm != null) {
            pickupDistanceKm.add(tripDistanceKm)
        } else {
            null
        }
        val totalDurationMin = if (pickupEtaMin != null && tripDurationMin != null) {
            pickupEtaMin + tripDurationMin
        } else {
            null
        }
        val farePerKm = if (fareAmount != null && totalDistanceKm != null && totalDistanceKm > BigDecimal.ZERO) {
            fareAmount.divide(totalDistanceKm, 2, RoundingMode.HALF_UP)
        } else {
            null
        }
        val farePerHour = if (fareAmount != null && totalDurationMin != null && totalDurationMin > 0) {
            fareAmount
                .multiply(BigDecimal("60"))
                .divide(BigDecimal.valueOf(totalDurationMin.toLong()), 2, RoundingMode.HALF_UP)
        } else {
            null
        }
        return ParsedOfferMetrics(
            farePerKm = farePerKm,
            farePerHour = farePerHour,
            totalDistanceKm = totalDistanceKm,
            totalDurationMin = totalDurationMin,
        )
    }

    private fun parseDistanceKm(text: String?): BigDecimal? {
        if (text.isNullOrBlank()) {
            return null
        }
        val match = DISTANCE_PATTERN.find(normalizeText(text)) ?: return null
        return match.groupValues[1].replace(',', '.').toBigDecimalOrNull()
    }

    private fun parseDurationMin(text: String?): Int? {
        if (text.isNullOrBlank()) {
            return null
        }
        val match = DURATION_PATTERN.find(normalizeText(text)) ?: return null
        return match.groupValues[1].toIntOrNull()
    }

    private fun centsToAmount(cents: Long): BigDecimal {
        return BigDecimal.valueOf(cents).movePointLeft(2)
    }

    private fun formatDecimal(value: BigDecimal): String {
        return value.setScale(2, RoundingMode.HALF_UP).toPlainString().replace('.', ',')
    }

    private fun formatSingleDecimal(value: BigDecimal): String {
        return value.setScale(1, RoundingMode.HALF_UP).toPlainString().replace('.', ',')
    }

    private fun missingFieldLabel(field: String): String {
        return when (field) {
            "cta" -> "CTA ausente."
            "fare_amount" -> "Valor ausente."
            "pickup_distance" -> "Distância de embarque ausente."
            "trip_distance" -> "Distância da viagem ausente."
            else -> "Campo ausente: $field."
        }
    }

    private fun normalizeText(text: String): String {
        return text
            .lowercase(Locale.ROOT)
            .replace('\u00A0', ' ')
            .replace('\u2007', ' ')
            .replace('\u202f', ' ')
            .trim()
    }

    private data class ParsedOfferMetrics(
        val farePerKm: BigDecimal?,
        val farePerHour: BigDecimal?,
        val totalDistanceKm: BigDecimal?,
        val totalDurationMin: Int?,
    )
}
