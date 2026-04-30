package com.example.despesas_frontend.driver

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.util.Locale

data class DriverSignalPreferences(
    val minGreenFarePerKm: BigDecimal,
    val minYellowFarePerKm: BigDecimal,
    val minGreenFarePerHour: BigDecimal,
    val minYellowFarePerHour: BigDecimal,
    val minTotalFare: BigDecimal,
    val maxTotalDistanceKm: BigDecimal,
    val maxTotalDurationMin: Int,
    val updatedAt: String,
    val source: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "minGreenFarePerKm" to minGreenFarePerKm.toDouble(),
            "minYellowFarePerKm" to minYellowFarePerKm.toDouble(),
            "minGreenFarePerHour" to minGreenFarePerHour.toDouble(),
            "minYellowFarePerHour" to minYellowFarePerHour.toDouble(),
            "minTotalFare" to minTotalFare.toDouble(),
            "maxTotalDistanceKm" to maxTotalDistanceKm.toDouble(),
            "maxTotalDurationMin" to maxTotalDurationMin,
            "updatedAt" to updatedAt,
            "source" to source,
        )
    }

    fun withSource(source: String, updatedAt: String): DriverSignalPreferences {
        return copy(source = source, updatedAt = updatedAt)
    }

    fun formatDecimal(value: BigDecimal): String {
        return value.setScale(2, RoundingMode.HALF_UP).toPlainString().replace('.', ',')
    }

    companion object {
        fun defaults(): DriverSignalPreferences {
            return DriverSignalPreferences(
                minGreenFarePerKm = BigDecimal("2.00"),
                minYellowFarePerKm = BigDecimal("1.50"),
                minGreenFarePerHour = BigDecimal("45.00"),
                minYellowFarePerHour = BigDecimal("30.00"),
                minTotalFare = BigDecimal("10.00"),
                maxTotalDistanceKm = BigDecimal("25.00"),
                maxTotalDurationMin = 60,
                updatedAt = "",
                source = "DEFAULT",
            )
        }
    }
}

data class DriverSignalPreferencesValidation(
    val preferences: DriverSignalPreferences?,
    val errors: List<String>,
)

internal object DriverSignalPreferencesValidator {
    fun validate(
        raw: Map<String, Any?>,
        updatedAt: Instant,
    ): DriverSignalPreferencesValidation {
        val minGreenFarePerKm = parseDecimal(raw["minGreenFarePerKm"])
        val minYellowFarePerKm = parseDecimal(raw["minYellowFarePerKm"])
        val minGreenFarePerHour = parseDecimal(raw["minGreenFarePerHour"])
        val minYellowFarePerHour = parseDecimal(raw["minYellowFarePerHour"])
        val minTotalFare = parseDecimal(raw["minTotalFare"])
        val maxTotalDistanceKm = parseDecimal(raw["maxTotalDistanceKm"])
        val maxTotalDurationMin = parsePositiveInt(raw["maxTotalDurationMin"])

        val errors = mutableListOf<String>()

        if (minGreenFarePerKm == null) errors += "Verde por km deve ser um número válido."
        if (minYellowFarePerKm == null) errors += "Amarelo por km deve ser um número válido."
        if (minGreenFarePerHour == null) errors += "Verde por hora deve ser um número válido."
        if (minYellowFarePerHour == null) errors += "Amarelo por hora deve ser um número válido."
        if (minTotalFare == null) errors += "Valor mínimo deve ser um número válido."
        if (maxTotalDistanceKm == null) errors += "Distância máxima deve ser um número válido."
        if (maxTotalDurationMin == null) errors += "Tempo máximo deve ser um número inteiro válido."

        listOf(
            minGreenFarePerKm to "Verde por km",
            minYellowFarePerKm to "Amarelo por km",
            minGreenFarePerHour to "Verde por hora",
            minYellowFarePerHour to "Amarelo por hora",
            minTotalFare to "Valor mínimo",
            maxTotalDistanceKm to "Distância máxima",
        ).forEach { (value, label) ->
            if (value != null && value < BigDecimal.ZERO) {
                errors += "$label não pode ser negativo."
            }
        }
        if (maxTotalDurationMin != null && maxTotalDurationMin <= 0) {
            errors += "Tempo máximo deve ser maior que zero."
        }
        if (maxTotalDistanceKm != null && maxTotalDistanceKm <= BigDecimal.ZERO) {
            errors += "Distância máxima deve ser maior que zero."
        }
        if (minGreenFarePerKm != null && minYellowFarePerKm != null &&
            minGreenFarePerKm < minYellowFarePerKm
        ) {
            errors += "Verde por km deve ser maior ou igual ao amarelo por km."
        }
        if (minGreenFarePerHour != null && minYellowFarePerHour != null &&
            minGreenFarePerHour < minYellowFarePerHour
        ) {
            errors += "Verde por hora deve ser maior ou igual ao amarelo por hora."
        }

        if (errors.isNotEmpty()) {
            return DriverSignalPreferencesValidation(
                preferences = null,
                errors = errors,
            )
        }

        return DriverSignalPreferencesValidation(
            preferences = DriverSignalPreferences(
                minGreenFarePerKm = minGreenFarePerKm!!,
                minYellowFarePerKm = minYellowFarePerKm!!,
                minGreenFarePerHour = minGreenFarePerHour!!,
                minYellowFarePerHour = minYellowFarePerHour!!,
                minTotalFare = minTotalFare!!,
                maxTotalDistanceKm = maxTotalDistanceKm!!,
                maxTotalDurationMin = maxTotalDurationMin!!,
                updatedAt = updatedAt.toString(),
                source = "USER_CONFIGURED",
            ),
            errors = emptyList(),
        )
    }

    private fun parseDecimal(raw: Any?): BigDecimal? {
        val normalized = when (raw) {
            is Number -> raw.toString()
            is String -> raw
            else -> return null
        }
            .trim()
            .replace('\u00A0', ' ')
            .replace('\u2007', ' ')
            .replace('\u202f', ' ')
            .replace(" ", "")
            .replace(',', '.')

        if (normalized.isBlank()) {
            return null
        }

        return normalized.toBigDecimalOrNull()?.setScale(2, RoundingMode.HALF_UP)
    }

    private fun parsePositiveInt(raw: Any?): Int? {
        return when (raw) {
            is Number -> raw.toInt()
            is String -> raw.trim().toIntOrNull()
            else -> null
        }
    }
}
