package com.example.despesas_frontend.driver

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UberOfferParserTest {
    @Test
    fun `evento 03 gera parsing estruturado completo`() {
        val offer = parseFixture(
            resourceName = "driver/uber_event_03_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertNotNull(offer)
        assertEquals("Comfort", offer?.productName)
        assertEquals("R\$ 10,02", offer?.fareAmountText)
        assertEquals(1002L, offer?.fareAmountCents)
        assertEquals("8 min", offer?.pickupEtaText)
        assertEquals("2.9 km", offer?.pickupDistanceText)
        assertEquals("6 minutos", offer?.tripDurationText)
        assertEquals("2.2 km", offer?.tripDistanceText)
        assertEquals("Quietude, Praia Grande", offer?.primaryLocationText)
        assertEquals(
            "Rua Emílio de Menezes, 162, Cidade Ocian, Praia Grande",
            offer?.secondaryLocationText,
        )
        assertEquals("Selecionar", offer?.ctaText)
        assertEquals("HIGH", offer?.confidence)
        assertTrue(offer?.missingFields?.isEmpty() == true)
    }

    @Test
    fun `evento 06 gera parsing estruturado completo`() {
        val offer = parseFixture(
            resourceName = "driver/uber_event_06_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertNotNull(offer)
        assertEquals("UberX", offer?.productName)
        assertEquals("R\$ 37,37", offer?.fareAmountText)
        assertEquals(3737L, offer?.fareAmountCents)
        assertEquals("5 min", offer?.pickupEtaText)
        assertEquals("2.0 km", offer?.pickupDistanceText)
        assertEquals("33 minutos", offer?.tripDurationText)
        assertEquals("22.0 km", offer?.tripDistanceText)
        assertEquals(
            "Rua Antônio Monteiro, Balneário Maracanã, Praia Grande",
            offer?.primaryLocationText,
        )
        assertEquals(
            "Avenida Washington Luís, 483, Boqueirão, Santos",
            offer?.secondaryLocationText,
        )
        assertEquals("Selecionar", offer?.ctaText)
        assertTrue(offer?.missingFields?.isEmpty() == true)
    }

    @Test
    fun `evento 08 gera parsing estruturado completo`() {
        val offer = parseFixture(
            resourceName = "driver/uber_event_08_actionable_offer.txt",
            classification = "ACTIONABLE_OFFER",
            isActionable = true,
        )

        assertNotNull(offer)
        assertEquals("UberX", offer?.productName)
        assertEquals("R\$ 6,93", offer?.fareAmountText)
        assertEquals(693L, offer?.fareAmountCents)
        assertEquals("6 min", offer?.pickupEtaText)
        assertEquals("1.9 km", offer?.pickupDistanceText)
        assertEquals("6 minutos", offer?.tripDurationText)
        assertEquals("1.6 km", offer?.tripDistanceText)
        assertEquals(
            "Avenida da Integração, Jardim Quietude, Praia Grande",
            offer?.primaryLocationText,
        )
        assertEquals(
            "Av. Ananias Batista Menezes, 1012, Nova Mirim, Praia Grande",
            offer?.secondaryLocationText,
        )
        assertEquals("Selecionar", offer?.ctaText)
        assertTrue(offer?.missingFields?.isEmpty() == true)
    }

    @Test
    fun `evento 07 permite parsing parcial sem virar acionável`() {
        val offer = parseFixture(
            resourceName = "driver/uber_event_07_offer_candidate.txt",
            classification = "OFFER_CANDIDATE",
            isActionable = false,
        )

        assertNotNull(offer)
        assertEquals("OFFER_CANDIDATE", offer?.classification)
        assertFalse(offer?.isActionable == true)
        assertEquals("UberX", offer?.productName)
        assertEquals("R\$ 37,37", offer?.fareAmountText)
        assertEquals(3737L, offer?.fareAmountCents)
        assertEquals("5 min", offer?.pickupEtaText)
        assertEquals("2.0 km", offer?.pickupDistanceText)
        assertEquals("33 minutos", offer?.tripDurationText)
        assertEquals("22.0 km", offer?.tripDistanceText)
        assertNull(offer?.ctaText)
        assertTrue(offer?.missingFields?.contains("cta") == true)
        assertEquals("MEDIUM", offer?.confidence)
    }

    @Test
    fun `expirado ou perdido não gera parsing estruturado`() {
        val fixtures = listOf(
            "driver/uber_event_01_expired_or_missed.txt",
            "driver/uber_event_02_expired_or_missed.txt",
            "driver/uber_event_04_expired_or_missed.txt",
            "driver/uber_event_05_expired_or_missed.txt",
        )

        fixtures.forEach { resourceName ->
            val offer = parseFixture(
                resourceName = resourceName,
                classification = "OFFER_EXPIRED_OR_MISSED",
                isActionable = false,
            )
            assertNull(offer)
        }
    }

    private fun parseFixture(
        resourceName: String,
        classification: String,
        isActionable: Boolean,
    ): DriverStructuredOffer? {
        return UberOfferParser.parse(
            providerKey = "UBER_DRIVER",
            classification = classification,
            isActionable = isActionable,
            texts = loadFixtureTexts(resourceName),
            parsedAt = Instant.parse("2026-04-29T12:00:00Z"),
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
