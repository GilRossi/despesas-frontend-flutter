package com.example.despesas_frontend.driver

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.util.Locale

data class DriverStructuredOffer(
    val providerKey: String,
    val classification: String,
    val isActionable: Boolean,
    val productName: String?,
    val fareAmountText: String?,
    val fareAmountCents: Long?,
    val pickupEtaText: String?,
    val pickupDistanceText: String?,
    val tripDurationText: String?,
    val tripDistanceText: String?,
    val primaryLocationText: String?,
    val secondaryLocationText: String?,
    val ctaText: String?,
    val confidence: String,
    val missingFields: List<String>,
    val rawTexts: List<String>,
    val parsedAt: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "providerKey" to providerKey,
            "classification" to classification,
            "isActionable" to isActionable,
            "productName" to productName,
            "fareAmountText" to fareAmountText,
            "fareAmountCents" to fareAmountCents,
            "pickupEtaText" to pickupEtaText,
            "pickupDistanceText" to pickupDistanceText,
            "tripDurationText" to tripDurationText,
            "tripDistanceText" to tripDistanceText,
            "primaryLocationText" to primaryLocationText,
            "secondaryLocationText" to secondaryLocationText,
            "ctaText" to ctaText,
            "confidence" to confidence,
            "missingFields" to missingFields,
            "rawTexts" to rawTexts,
            "parsedAt" to parsedAt,
        )
    }
}

internal object UberOfferParser {
    private val MONEY_PATTERN = Regex(
        """(?i)\br\$\s*(\d{1,3}(?:\.\d{3})*|\d+)([.,]\d{2})\b""",
    )
    private val ROUTE_PATTERN = Regex(
        """(?i)\b(\d+\s*(?:min|minutos))\s*\((\d+[.,]?\d*\s*km)\)""",
    )
    private val STRONG_CTA_PATTERN = Regex(
        """(?i)\b(selecionar|aceitar corrida|aceitar viagem)\b""",
    )
    private val PRODUCT_PATTERN = Regex(
        """(?i)^(uberx|comfort|flash|black|moto)$""",
    )
    private val RATING_PATTERN = Regex("""^\d+[.,]\d+\s*\(\d+\)$""")
    private val ADDRESS_HINTS = listOf(
        "rua ",
        "avenida ",
        "av. ",
        "alameda ",
        "travessa ",
        "rodovia ",
        "praça ",
        "praca ",
        "estrada ",
        "jardim ",
        "balneário ",
        "balneario ",
        "quietude",
        "ocian",
        "mirim",
        "boqueirão",
        "boqueirao",
        "praia grande",
        "santos",
    )
    private val NON_LOCATION_HINTS = listOf(
        "viagem longa",
        "encontramos outro motorista parceiro",
    )

    fun parse(
        providerKey: String,
        classification: String,
        isActionable: Boolean,
        texts: List<String>,
        parsedAt: Instant,
    ): DriverStructuredOffer? {
        if (classification != "ACTIONABLE_OFFER" && classification != "OFFER_CANDIDATE") {
            return null
        }

        val rawTexts = texts
            .map(String::trim)
            .filter(String::isNotBlank)
            .distinct()

        if (rawTexts.isEmpty()) {
            return null
        }

        val productName = rawTexts.firstOrNull(::isProductSignal)
        val fareAmountText = rawTexts.firstOrNull(::isPositiveMoneySignal)
        val fareAmountCents = fareAmountText?.let(::parseMoneyToCents)
        val routeLines = rawTexts.filter(::isRouteMetricsSignal)
        val pickupMetrics = routeLines.getOrNull(0)?.let(::parseRouteLine)
        val tripMetrics = routeLines.getOrNull(1)?.let(::parseRouteLine)
        val locationCandidates = rawTexts.filter(::isLocationCandidate)
        val primaryLocationText = locationCandidates.getOrNull(0)
        val secondaryLocationText = locationCandidates
            .drop(1)
            .firstOrNull { candidate -> candidate != primaryLocationText }
        val ctaText = rawTexts.firstOrNull(::isStrongCtaSignal)

        val missingFields = buildList {
            if (fareAmountText == null || fareAmountCents == null) add("fare_amount")
            if (productName == null) add("product_name")
            if (pickupMetrics?.durationText == null) add("pickup_eta")
            if (pickupMetrics?.distanceText == null) add("pickup_distance")
            if (tripMetrics?.durationText == null) add("trip_duration")
            if (tripMetrics?.distanceText == null) add("trip_distance")
            if (primaryLocationText == null) add("primary_location")
            if (secondaryLocationText == null) add("secondary_location")
            if (ctaText == null) add("cta")
        }

        return DriverStructuredOffer(
            providerKey = providerKey,
            classification = classification,
            isActionable = isActionable,
            productName = productName,
            fareAmountText = fareAmountText,
            fareAmountCents = fareAmountCents,
            pickupEtaText = pickupMetrics?.durationText,
            pickupDistanceText = pickupMetrics?.distanceText,
            tripDurationText = tripMetrics?.durationText,
            tripDistanceText = tripMetrics?.distanceText,
            primaryLocationText = primaryLocationText,
            secondaryLocationText = secondaryLocationText,
            ctaText = ctaText,
            confidence = parsingConfidence(
                classification = classification,
                isActionable = isActionable,
                missingFields = missingFields,
            ),
            missingFields = missingFields,
            rawTexts = rawTexts,
            parsedAt = parsedAt.toString(),
        )
    }

    private fun parsingConfidence(
        classification: String,
        isActionable: Boolean,
        missingFields: List<String>,
    ): String {
        if (isActionable && missingFields.isEmpty()) {
            return "HIGH"
        }
        if (classification == "ACTIONABLE_OFFER" && missingFields.size <= 2) {
            return "MEDIUM"
        }
        if (classification == "OFFER_CANDIDATE" && missingFields.contains("cta")) {
            return "MEDIUM"
        }
        return "LOW"
    }

    private fun parseMoneyToCents(text: String): Long? {
        val match = MONEY_PATTERN.find(normalizeText(text)) ?: return null
        val normalizedNumber = buildString {
            append(match.groupValues[1].replace(".", ""))
            append(match.groupValues[2].replace(',', '.'))
        }
        return runCatching {
            BigDecimal(normalizedNumber)
                .movePointRight(2)
                .setScale(0, RoundingMode.HALF_UP)
                .longValueExact()
        }.getOrNull()
    }

    private fun parseRouteLine(text: String): ParsedRouteMetrics? {
        val match = ROUTE_PATTERN.find(normalizeText(text)) ?: return null
        return ParsedRouteMetrics(
            durationText = match.groupValues[1].trim(),
            distanceText = match.groupValues[2].trim(),
        )
    }

    private fun isPositiveMoneySignal(text: String): Boolean {
        val normalized = normalizeText(text)
        return MONEY_PATTERN.containsMatchIn(normalized) && !normalized.contains("-r$")
    }

    private fun isStrongCtaSignal(text: String): Boolean {
        return STRONG_CTA_PATTERN.containsMatchIn(normalizeText(text))
    }

    private fun isRouteMetricsSignal(text: String): Boolean {
        return ROUTE_PATTERN.containsMatchIn(normalizeText(text))
    }

    private fun isProductSignal(text: String): Boolean {
        return PRODUCT_PATTERN.matches(normalizeText(text))
    }

    private fun isLocationCandidate(text: String): Boolean {
        val normalized = normalizeText(text)
        if (normalized.isBlank()) {
            return false
        }
        if (isProductSignal(text) ||
            isPositiveMoneySignal(text) ||
            isStrongCtaSignal(text) ||
            isRouteMetricsSignal(text) ||
            RATING_PATTERN.matches(normalized)
        ) {
            return false
        }
        if (NON_LOCATION_HINTS.any { hint -> normalized.contains(hint) }) {
            return false
        }
        return ADDRESS_HINTS.any { hint -> normalized.contains(hint) } ||
            (normalized.contains(",") && normalized.any(Char::isLetter))
    }

    private fun normalizeText(text: String): String {
        return text
            .lowercase(Locale.ROOT)
            .replace('\u00A0', ' ')
            .replace('\u2007', ' ')
            .replace('\u202F', ' ')
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}

private data class ParsedRouteMetrics(
    val durationText: String,
    val distanceText: String,
)
