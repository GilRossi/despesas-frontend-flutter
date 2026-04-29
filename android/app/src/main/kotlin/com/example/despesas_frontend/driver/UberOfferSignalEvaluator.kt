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
    val farePerMinuteText: String?,
    val estimatedTotalDistanceKm: Double?,
    val estimatedTotalDurationMin: Int?,
    val estimatedTotalDistanceText: String?,
    val estimatedTotalDurationText: String?,
    val ruleVersion: String,
    val computedAt: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "color" to color,
            "label" to label,
            "reason" to reason,
            "warnings" to warnings,
            "farePerKmText" to farePerKmText,
            "farePerMinuteText" to farePerMinuteText,
            "estimatedTotalDistanceKm" to estimatedTotalDistanceKm,
            "estimatedTotalDurationMin" to estimatedTotalDurationMin,
            "estimatedTotalDistanceText" to estimatedTotalDistanceText,
            "estimatedTotalDurationText" to estimatedTotalDurationText,
            "ruleVersion" to ruleVersion,
            "computedAt" to computedAt,
        )
    }
}

internal object UberOfferSignalEvaluator {
    const val RULE_VERSION = "UBER_SIGNAL_V1"

    private val DISTANCE_PATTERN = Regex("""(\d+[.,]?\d*)\s*km""", RegexOption.IGNORE_CASE)
    private val DURATION_PATTERN = Regex("""(\d+)\s*(?:min|minutos)""", RegexOption.IGNORE_CASE)
    private val LOW_TOTAL_FARE = BigDecimal("10.00")
    private val GREEN_MIN_FARE_PER_KM = BigDecimal("2.00")
    private val YELLOW_MIN_FARE_PER_KM = BigDecimal("1.50")
    private val MAX_GREEN_DISTANCE_KM = BigDecimal("25.0")
    private val HIGH_DISTANCE_WARNING_KM = BigDecimal("20.0")
    private const val HIGH_DURATION_WARNING_MIN = 35

    fun evaluate(
        offer: DriverStructuredOffer,
        computedAt: Instant,
    ): DriverOfferSignal {
        val warnings = mutableListOf<String>()
        val metrics = parseMetrics(offer)
        val fareAmount = offer.fareAmountCents?.let(::centsToAmount)

        if (fareAmount != null && fareAmount < LOW_TOTAL_FARE) {
            warnings += "Valor total baixo."
        }
        if (metrics.totalDistanceKm != null && metrics.totalDistanceKm > HIGH_DISTANCE_WARNING_KM) {
            warnings += "Distância total alta."
        }
        if (metrics.totalDurationMin != null && metrics.totalDurationMin > HIGH_DURATION_WARNING_MIN) {
            warnings += "Tempo total alto."
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
                farePerMinute = metrics.farePerMinute,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                computedAt = computedAt,
            )
        }

        if (fareAmount == null || metrics.totalDistanceKm == null || metrics.totalDurationMin == null ||
            metrics.farePerKm == null || metrics.farePerMinute == null
        ) {
            warnings += "Dados insuficientes para decidir com segurança."
            return signal(
                color = "RED",
                label = "Vermelho",
                reason = "Farol indisponível por dados insuficientes.",
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerMinute = metrics.farePerMinute,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                computedAt = computedAt,
            )
        }

        if (metrics.farePerKm >= GREEN_MIN_FARE_PER_KM &&
            fareAmount >= LOW_TOTAL_FARE &&
            metrics.totalDistanceKm <= MAX_GREEN_DISTANCE_KM
        ) {
            return signal(
                color = "GREEN",
                label = "Verde",
                reason = "Valor por km forte para a regra v1.",
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerMinute = metrics.farePerMinute,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                computedAt = computedAt,
            )
        }

        if (metrics.farePerKm >= YELLOW_MIN_FARE_PER_KM) {
            val reason = when {
                fareAmount < LOW_TOTAL_FARE -> "Oferta acionável, mas com valor total baixo."
                metrics.totalDistanceKm > HIGH_DISTANCE_WARNING_KM ||
                    metrics.totalDurationMin > HIGH_DURATION_WARNING_MIN ->
                    "Oferta acionável, mas com distância ou tempo altos."
                else -> "Oferta acionável, mas abaixo do patamar verde da regra v1."
            }
            return signal(
                color = "YELLOW",
                label = "Amarelo",
                reason = reason,
                warnings = warnings.distinct(),
                farePerKm = metrics.farePerKm,
                farePerMinute = metrics.farePerMinute,
                totalDistanceKm = metrics.totalDistanceKm,
                totalDurationMin = metrics.totalDurationMin,
                computedAt = computedAt,
            )
        }

        return signal(
            color = "RED",
            label = "Vermelho",
            reason = "Valor por km abaixo do mínimo da regra v1.",
            warnings = warnings.distinct(),
            farePerKm = metrics.farePerKm,
            farePerMinute = metrics.farePerMinute,
            totalDistanceKm = metrics.totalDistanceKm,
            totalDurationMin = metrics.totalDurationMin,
            computedAt = computedAt,
        )
    }

    private fun signal(
        color: String,
        label: String,
        reason: String,
        warnings: List<String>,
        farePerKm: BigDecimal?,
        farePerMinute: BigDecimal?,
        totalDistanceKm: BigDecimal?,
        totalDurationMin: Int?,
        computedAt: Instant,
    ): DriverOfferSignal {
        return DriverOfferSignal(
            color = color,
            label = label,
            reason = reason,
            warnings = warnings,
            farePerKmText = farePerKm?.let { "R$ ${formatDecimal(it)}/km" },
            farePerMinuteText = farePerMinute?.let { "R$ ${formatDecimal(it)}/min" },
            estimatedTotalDistanceKm = totalDistanceKm?.toDouble(),
            estimatedTotalDurationMin = totalDurationMin,
            estimatedTotalDistanceText = totalDistanceKm?.let { "${formatSingleDecimal(it)} km" },
            estimatedTotalDurationText = totalDurationMin?.let { "$it min" },
            ruleVersion = RULE_VERSION,
            computedAt = computedAt.toString(),
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
        val farePerMinute = if (fareAmount != null && totalDurationMin != null && totalDurationMin > 0) {
            fareAmount.divide(BigDecimal.valueOf(totalDurationMin.toLong()), 2, RoundingMode.HALF_UP)
        } else {
            null
        }
        return ParsedOfferMetrics(
            farePerKm = farePerKm,
            farePerMinute = farePerMinute,
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
        val farePerMinute: BigDecimal?,
        val totalDistanceKm: BigDecimal?,
        val totalDurationMin: Int?,
    )
}
