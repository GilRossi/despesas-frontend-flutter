package com.example.despesas_frontend.driver

import java.math.BigDecimal
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UberOfferSignalEvaluatorTest {
    @Test
    fun `evento 03 gera farol yellow perto do limite verde com preferencias default`() {
        val signal = evaluateFixture(
            resourceName = "driver/uber_event_03_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertEquals("YELLOW", signal?.color)
        assertEquals("R$ 1,96/km", signal?.farePerKmText)
        assertEquals("R$ 42,94/h", signal?.farePerHourText)
        assertEquals("5,1 km", signal?.estimatedTotalDistanceText)
        assertEquals("14 min", signal?.estimatedTotalDurationText)
        assertTrue(signal?.reason?.contains("patamar verde configurado") == true)
        assertEquals("DEFAULT", signal?.preferencesSource)
        assertEquals("UBER_SIGNAL_V1_CONFIGURABLE", signal?.ruleVersion)
    }

    @Test
    fun `evento 06 gera farol yellow com alerta de distancia perto do limite`() {
        val signal = evaluateFixture(
            resourceName = "driver/uber_event_06_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertEquals("YELLOW", signal?.color)
        assertEquals("R$ 1,56/km", signal?.farePerKmText)
        assertEquals("R$ 59,01/h", signal?.farePerHourText)
        assertEquals("24,0 km", signal?.estimatedTotalDistanceText)
        assertEquals("38 min", signal?.estimatedTotalDurationText)
        assertTrue(signal?.warnings?.contains("Distância total perto do limite configurado.") == true)
    }

    @Test
    fun `evento 08 gera farol yellow com alerta de valor total baixo`() {
        val signal = evaluateFixture(
            resourceName = "driver/uber_event_08_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertEquals("YELLOW", signal?.color)
        assertEquals("R$ 1,98/km", signal?.farePerKmText)
        assertEquals("R$ 34,65/h", signal?.farePerHourText)
        assertEquals("3,5 km", signal?.estimatedTotalDistanceText)
        assertEquals("12 min", signal?.estimatedTotalDurationText)
        assertTrue(signal?.warnings?.contains("Valor total baixo.") == true)
    }

    @Test
    fun `evento 07 gera red por candidato sem cta forte`() {
        val signal = evaluateFixture(
            resourceName = "driver/uber_event_07_offer_candidate.txt",
            classification = "OFFER_CANDIDATE",
            isActionable = false,
        )

        assertEquals("RED", signal?.color)
        assertEquals("R$ 1,56/km", signal?.farePerKmText)
        assertEquals("R$ 59,01/h", signal?.farePerHourText)
        assertTrue(signal?.reason?.contains("falta requisito crítico") == true)
        assertTrue(signal?.warnings?.contains("CTA ausente.") == true)
    }

    @Test
    fun `thresholds do usuario podem promover oferta para green`() {
        val signal = evaluateFixture(
            resourceName = "driver/uber_event_03_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
            preferences = DriverSignalPreferences.defaults().copy(
                minGreenFarePerKm = BigDecimal("1.90"),
                minGreenFarePerHour = BigDecimal("40.00"),
                source = "USER_CONFIGURED",
            ),
        )

        assertEquals("GREEN", signal?.color)
        assertEquals("USER_CONFIGURED", signal?.preferencesSource)
        assertTrue(signal?.reason?.contains("limites verdes configurados") == true)
    }

    @Test
    fun `expirado ou perdido nao gera farol estruturado`() {
        val fixtures = listOf(
            "driver/uber_event_01_expired_or_missed.txt",
            "driver/uber_event_02_expired_or_missed.txt",
            "driver/uber_event_04_expired_or_missed.txt",
            "driver/uber_event_05_expired_or_missed.txt",
        )

        fixtures.forEach { resourceName ->
            val structuredOffer = UberOfferParser.parse(
                providerKey = "UBER_DRIVER",
                classification = "OFFER_EXPIRED_OR_MISSED",
                isActionable = false,
                texts = loadFixtureTexts(resourceName),
                parsedAt = Instant.parse("2026-04-29T12:00:00Z"),
            )
            assertNull(structuredOffer)
        }
    }

    @Test
    fun `valor negativo nao vira farol acionavel`() {
        val offer = DriverStructuredOffer(
            providerKey = "UBER_DRIVER",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
            productName = "UberX",
            fareAmountText = "-R$ 0,01",
            fareAmountCents = null,
            pickupEtaText = "5 min",
            pickupDistanceText = "2.0 km",
            tripDurationText = "12 minutos",
            tripDistanceText = "5.0 km",
            primaryLocationText = "Rua Exemplo",
            secondaryLocationText = "Av. Destino",
            ctaText = "Selecionar",
            confidence = "LOW",
            missingFields = listOf("fare_amount"),
            rawTexts = listOf("-R$ 0,01"),
            parsedAt = "2026-04-29T12:00:00Z",
        )

        val signal = UberOfferSignalEvaluator.evaluate(
            offer = offer,
            preferences = DriverSignalPreferences.defaults(),
            computedAt = Instant.parse("2026-04-29T12:00:01Z"),
        )

        assertEquals("RED", signal.color)
        assertTrue(signal.reason.contains("dados insuficientes"))
        assertFalse(signal.warnings.isEmpty())
    }

    private fun evaluateFixture(
        resourceName: String,
        classification: String,
        isActionable: Boolean,
        preferences: DriverSignalPreferences = DriverSignalPreferences.defaults(),
    ): DriverOfferSignal? {
        val offer = UberOfferParser.parse(
            providerKey = "UBER_DRIVER",
            classification = classification,
            isActionable = isActionable,
            texts = loadFixtureTexts(resourceName),
            parsedAt = Instant.parse("2026-04-29T12:00:00Z"),
        ) ?: return null

        return UberOfferSignalEvaluator.evaluate(
            offer = offer,
            preferences = preferences,
            computedAt = Instant.parse("2026-04-29T12:00:01Z"),
        )
    }

    private fun loadFixtureTexts(resourceName: String): List<String> {
        val resourceStream = checkNotNull(
            javaClass.classLoader?.getResourceAsStream(resourceName),
        )
        return resourceStream
            .bufferedReader()
            .readLines()
            .map(String::trim)
            .filter(String::isNotBlank)
    }
}
