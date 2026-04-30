package com.example.despesas_frontend.driver

import android.content.Context
import android.content.SharedPreferences
import java.time.Instant

interface DriverSignalPreferencesStore {
    fun getString(key: String): String?

    fun save(values: Map<String, String>)

    fun remove(keys: List<String>)
}

class AndroidDriverSignalPreferencesStore(
    context: Context,
) : DriverSignalPreferencesStore {
    private val sharedPreferences: SharedPreferences = context.getSharedPreferences(
        "driver_signal_preferences",
        Context.MODE_PRIVATE,
    )

    override fun getString(key: String): String? {
        return sharedPreferences.getString(key, null)
    }

    override fun save(values: Map<String, String>) {
        sharedPreferences.edit().apply {
            values.forEach { (key, value) -> putString(key, value) }
        }.apply()
    }

    override fun remove(keys: List<String>) {
        sharedPreferences.edit().apply {
            keys.forEach(::remove)
        }.apply()
    }
}

class DriverSignalPreferencesRepository(
    private val store: DriverSignalPreferencesStore,
) {
    fun get(): DriverSignalPreferences {
        val defaults = DriverSignalPreferences.defaults()
        val source = store.getString(KEY_SOURCE) ?: return defaults

        return DriverSignalPreferences(
            minGreenFarePerKm = parseDecimal(store.getString(KEY_MIN_GREEN_FARE_PER_KM)) ?: defaults.minGreenFarePerKm,
            minYellowFarePerKm = parseDecimal(store.getString(KEY_MIN_YELLOW_FARE_PER_KM)) ?: defaults.minYellowFarePerKm,
            minGreenFarePerHour = parseDecimal(store.getString(KEY_MIN_GREEN_FARE_PER_HOUR)) ?: defaults.minGreenFarePerHour,
            minYellowFarePerHour = parseDecimal(store.getString(KEY_MIN_YELLOW_FARE_PER_HOUR)) ?: defaults.minYellowFarePerHour,
            minTotalFare = parseDecimal(store.getString(KEY_MIN_TOTAL_FARE)) ?: defaults.minTotalFare,
            maxTotalDistanceKm = parseDecimal(store.getString(KEY_MAX_TOTAL_DISTANCE_KM)) ?: defaults.maxTotalDistanceKm,
            maxTotalDurationMin = store.getString(KEY_MAX_TOTAL_DURATION_MIN)?.toIntOrNull()
                ?: defaults.maxTotalDurationMin,
            updatedAt = store.getString(KEY_UPDATED_AT).orEmpty(),
            source = source,
        )
    }

    fun save(raw: Map<String, Any?>, now: Instant): DriverSignalPreferencesValidation {
        val validation = DriverSignalPreferencesValidator.validate(raw, now)
        val preferences = validation.preferences ?: return validation

        store.save(
            mapOf(
                KEY_MIN_GREEN_FARE_PER_KM to preferences.minGreenFarePerKm.toPlainString(),
                KEY_MIN_YELLOW_FARE_PER_KM to preferences.minYellowFarePerKm.toPlainString(),
                KEY_MIN_GREEN_FARE_PER_HOUR to preferences.minGreenFarePerHour.toPlainString(),
                KEY_MIN_YELLOW_FARE_PER_HOUR to preferences.minYellowFarePerHour.toPlainString(),
                KEY_MIN_TOTAL_FARE to preferences.minTotalFare.toPlainString(),
                KEY_MAX_TOTAL_DISTANCE_KM to preferences.maxTotalDistanceKm.toPlainString(),
                KEY_MAX_TOTAL_DURATION_MIN to preferences.maxTotalDurationMin.toString(),
                KEY_UPDATED_AT to preferences.updatedAt,
                KEY_SOURCE to preferences.source,
            ),
        )
        return validation
    }

    fun reset() {
        store.remove(
            listOf(
                KEY_MIN_GREEN_FARE_PER_KM,
                KEY_MIN_YELLOW_FARE_PER_KM,
                KEY_MIN_GREEN_FARE_PER_HOUR,
                KEY_MIN_YELLOW_FARE_PER_HOUR,
                KEY_MIN_TOTAL_FARE,
                KEY_MAX_TOTAL_DISTANCE_KM,
                KEY_MAX_TOTAL_DURATION_MIN,
                KEY_UPDATED_AT,
                KEY_SOURCE,
            ),
        )
    }

    companion object {
        private const val KEY_MIN_GREEN_FARE_PER_KM = "min_green_fare_per_km"
        private const val KEY_MIN_YELLOW_FARE_PER_KM = "min_yellow_fare_per_km"
        private const val KEY_MIN_GREEN_FARE_PER_HOUR = "min_green_fare_per_hour"
        private const val KEY_MIN_YELLOW_FARE_PER_HOUR = "min_yellow_fare_per_hour"
        private const val KEY_MIN_TOTAL_FARE = "min_total_fare"
        private const val KEY_MAX_TOTAL_DISTANCE_KM = "max_total_distance_km"
        private const val KEY_MAX_TOTAL_DURATION_MIN = "max_total_duration_min"
        private const val KEY_UPDATED_AT = "updated_at"
        private const val KEY_SOURCE = "source"
    }

    private fun parseDecimal(raw: String?): java.math.BigDecimal? {
        if (raw.isNullOrBlank()) {
            return null
        }
        return raw.trim().replace(',', '.').toBigDecimalOrNull()
    }
}
