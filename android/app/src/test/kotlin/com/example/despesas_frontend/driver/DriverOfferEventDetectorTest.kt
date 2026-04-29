package com.example.despesas_frontend.driver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DriverOfferEventDetectorTest {
    @Test
    fun `evento 03 é classificado como actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            loadFixtureTexts("driver/uber_event_03_actionable_offer.txt"),
        )

        assertEquals("ACTIONABLE_OFFER", assessment.classification)
        assertTrue(assessment.isActionable)
        assertTrue(assessment.detectedSignals.any { it.contains("R\$ 10,02") })
        assertTrue(assessment.detectedSignals.any { it.contains("Selecionar") })
        assertTrue(assessment.detectedSignals.any { it.contains("Comfort") })
        assertTrue(assessment.missingRequirements.isEmpty())
    }

    @Test
    fun `evento 06 é classificado como actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            loadFixtureTexts("driver/uber_event_06_actionable_offer.txt"),
        )

        assertEquals("ACTIONABLE_OFFER", assessment.classification)
        assertTrue(assessment.isActionable)
        assertTrue(assessment.detectedSignals.any { it.contains("R\$ 37,37") })
        assertTrue(assessment.detectedSignals.any { it.contains("Selecionar") })
        assertTrue(assessment.detectedSignals.any { it.contains("UberX") })
    }

    @Test
    fun `evento 08 é classificado como actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            loadFixtureTexts("driver/uber_event_08_actionable_offer.txt"),
        )

        assertEquals("ACTIONABLE_OFFER", assessment.classification)
        assertTrue(assessment.isActionable)
        assertTrue(assessment.detectedSignals.any { it.contains("R\$ 6,93") })
        assertTrue(assessment.detectedSignals.any { it.contains("Selecionar") })
    }

    @Test
    fun `evento 07 é classificado como offer candidate sem virar acionável`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            loadFixtureTexts("driver/uber_event_07_offer_candidate.txt"),
        )

        assertEquals("OFFER_CANDIDATE", assessment.classification)
        assertFalse(assessment.isActionable)
        assertTrue(assessment.detectedSignals.any { it.contains("R\$ 37,37") })
        assertTrue(assessment.missingRequirements.contains("cta_forte"))
    }

    @Test
    fun `eventos 01 02 04 e 05 são classificados como expired or missed`() {
        val fixtures = listOf(
            "driver/uber_event_01_expired_or_missed.txt",
            "driver/uber_event_02_expired_or_missed.txt",
            "driver/uber_event_04_expired_or_missed.txt",
            "driver/uber_event_05_expired_or_missed.txt",
        )

        fixtures.forEach { fixture ->
            val assessment = DriverOfferEventDetector.assessOffer(
                loadFixtureTexts(fixture),
            )
            assertEquals("OFFER_EXPIRED_OR_MISSED", assessment.classification)
            assertFalse(assessment.isActionable)
            assertTrue(assessment.detectedSignals.any { it.contains("-R\$ 0,01") })
        }
    }

    @Test
    fun `valor positivo sem cta não vira actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            listOf(
                "UberX",
                "R\$ 14,90",
                "6 min (2.1 km)",
                "Rua Exemplo, Praia Grande",
            ),
        )

        assertEquals("OFFER_CANDIDATE", assessment.classification)
        assertFalse(assessment.isActionable)
        assertTrue(assessment.missingRequirements.contains("cta_forte"))
    }

    @Test
    fun `cta sem valor positivo não vira actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            listOf(
                "UberX",
                "Selecionar",
                "6 min (2.1 km)",
                "Rua Exemplo, Praia Grande",
            ),
        )

        assertFalse(assessment.isActionable)
        assertTrue(assessment.classification == "HOME_ONLINE" || assessment.classification == "OFFER_CANDIDATE")
        assertTrue(assessment.missingRequirements.contains("valor_positivo"))
    }

    @Test
    fun `valor negativo e estimativa de home não viram actionable offer`() {
        val assessment = DriverOfferEventDetector.assessOffer(
            loadFixtureTexts("driver/uber_event_02_expired_or_missed.txt"),
        )

        assertEquals("OFFER_EXPIRED_OR_MISSED", assessment.classification)
        assertFalse(assessment.isActionable)
    }

    @Test
    fun `detector potencial continua verdadeiro apenas para oferta forte com dinheiro cta e rota`() {
        val signals = DriverOfferEventDetector.detectOfferSignals(
            loadFixtureTexts("driver/uber_event_06_actionable_offer.txt"),
        )

        assertTrue(
            DriverOfferEventDetector.isPotentialOfferEvent(
                packageName = "com.ubercab.driver",
                eventType = "TYPE_WINDOW_CONTENT_CHANGED",
                detectedSignals = signals,
            ),
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
