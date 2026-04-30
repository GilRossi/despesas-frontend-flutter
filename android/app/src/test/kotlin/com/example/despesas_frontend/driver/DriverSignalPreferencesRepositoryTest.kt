package com.example.despesas_frontend.driver

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DriverSignalPreferencesRepositoryTest {
    @Test
    fun `fallback default funciona quando nao existe preferencia salva`() {
        val repository = DriverSignalPreferencesRepository(InMemoryStore())

        val preferences = repository.get()

        assertEquals("DEFAULT", preferences.source)
        assertEquals("2.00", preferences.minGreenFarePerKm.toPlainString())
        assertEquals("1.50", preferences.minYellowFarePerKm.toPlainString())
    }

    @Test
    fun `save persiste configuracao do usuario`() {
        val store = InMemoryStore()
        val repository = DriverSignalPreferencesRepository(store)

        val validation = repository.save(
            raw = mapOf(
                "minGreenFarePerKm" to "2,40",
                "minYellowFarePerKm" to "1,80",
                "minGreenFarePerHour" to "50",
                "minYellowFarePerHour" to "35",
                "minTotalFare" to "12",
                "maxTotalDistanceKm" to "20",
                "maxTotalDurationMin" to "45",
            ),
            now = Instant.parse("2026-04-29T14:00:00Z"),
        )

        assertTrue(validation.errors.isEmpty())
        val preferences = repository.get()
        assertEquals("USER_CONFIGURED", preferences.source)
        assertEquals("2026-04-29T14:00:00Z", preferences.updatedAt)
        assertEquals("2.40", preferences.minGreenFarePerKm.toPlainString())
        assertEquals("35.00", preferences.minYellowFarePerHour.toPlainString())
    }

    @Test
    fun `configuracao invalida e rejeitada`() {
        val repository = DriverSignalPreferencesRepository(InMemoryStore())

        val validation = repository.save(
            raw = mapOf(
                "minGreenFarePerKm" to "1,40",
                "minYellowFarePerKm" to "1,50",
                "minGreenFarePerHour" to "-1",
                "minYellowFarePerHour" to "30",
                "minTotalFare" to "10",
                "maxTotalDistanceKm" to "0",
                "maxTotalDurationMin" to "0",
            ),
            now = Instant.parse("2026-04-29T14:05:00Z"),
        )

        assertNull(validation.preferences)
        assertTrue(validation.errors.contains("Verde por km deve ser maior ou igual ao amarelo por km."))
        assertTrue(validation.errors.contains("Verde por hora não pode ser negativo."))
        assertTrue(validation.errors.contains("Distância máxima deve ser maior que zero."))
        assertTrue(validation.errors.contains("Tempo máximo deve ser maior que zero."))
    }

    @Test
    fun `reset volta para default`() {
        val store = InMemoryStore()
        val repository = DriverSignalPreferencesRepository(store)

        repository.save(
            raw = mapOf(
                "minGreenFarePerKm" to "2,40",
                "minYellowFarePerKm" to "1,80",
                "minGreenFarePerHour" to "50",
                "minYellowFarePerHour" to "35",
                "minTotalFare" to "12",
                "maxTotalDistanceKm" to "20",
                "maxTotalDurationMin" to "45",
            ),
            now = Instant.parse("2026-04-29T14:00:00Z"),
        )

        repository.reset()

        val preferences = repository.get()
        assertEquals("DEFAULT", preferences.source)
        assertEquals("", preferences.updatedAt)
    }

    private class InMemoryStore : DriverSignalPreferencesStore {
        private val values = linkedMapOf<String, String>()

        override fun getString(key: String): String? = values[key]

        override fun save(values: Map<String, String>) {
            this.values.putAll(values)
        }

        override fun remove(keys: List<String>) {
            keys.forEach(values::remove)
        }
    }
}
