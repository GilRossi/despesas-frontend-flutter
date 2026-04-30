package com.example.despesas_frontend.driver

import java.time.Instant
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DriverStateManagerTest {
    @After
    fun tearDown() {
        DriverStateManager.resetForTest()
    }

    @Test
    fun `Uber fica offline quando só existe CTA para ficar online`() {
        configureReadyUber()

        DriverStateManager.recordProviderEventAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_STATE_CHANGED",
            texts = listOf(
                "Página inicial",
                "Ganhos",
                "Mensagens",
                "Menu",
                "Ficar online",
            ),
            capturedAt = Instant.parse("2026-04-29T01:00:00Z"),
        )

        val snapshot = DriverStateManager.snapshotAt(
            Instant.parse("2026-04-29T01:00:01Z"),
        )

        assertEquals("OFFLINE", snapshot.currentContext.semanticState.code)
        assertEquals("RED", snapshot.signal.color)
        assertFalse(snapshot.currentContext.isActionable)
    }

    @Test
    fun `home online sem oferta vira HOME_ONLINE e não libera aceite`() {
        configureReadyUber()

        DriverStateManager.recordProviderEventAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_CONTENT_CHANGED",
            texts = listOf(
                "Você está online",
                "Procurando viagens",
                "Página inicial",
                "1-4 min",
                "1-2 min",
            ),
            capturedAt = Instant.parse("2026-04-29T01:01:00Z"),
        )

        val snapshot = DriverStateManager.snapshotAt(
            Instant.parse("2026-04-29T01:01:01Z"),
        )

        assertEquals("HOME_ONLINE", snapshot.currentContext.semanticState.code)
        assertEquals("GREEN", snapshot.signal.color)
        assertFalse(snapshot.currentContext.isActionable)
    }

    @Test
    fun `evento 03 gera ACTIONABLE_OFFER e lastOfferDetected verdadeiro`() {
        assertActionableFixture(
            resourceName = "driver/uber_event_03_actionable_offer.txt",
            expectedSignal = "R\$ 10,02",
            expectedProduct = "Comfort",
            capturedAt = Instant.parse("2026-04-29T01:02:00Z"),
            expectedOfferSignalColor = "YELLOW",
            expectedFarePerKmText = "R$ 1,96/km",
        )
    }

    @Test
    fun `evento 06 gera ACTIONABLE_OFFER e lastOfferDetected verdadeiro`() {
        assertActionableFixture(
            resourceName = "driver/uber_event_06_actionable_offer.txt",
            expectedSignal = "R\$ 37,37",
            expectedProduct = "UberX",
            capturedAt = Instant.parse("2026-04-29T01:03:00Z"),
            expectedOfferSignalColor = "YELLOW",
            expectedFarePerKmText = "R$ 1,56/km",
        )
    }

    @Test
    fun `evento 08 gera ACTIONABLE_OFFER e lastOfferDetected verdadeiro`() {
        assertActionableFixture(
            resourceName = "driver/uber_event_08_actionable_offer.txt",
            expectedSignal = "R\$ 6,93",
            expectedProduct = "UberX",
            capturedAt = Instant.parse("2026-04-29T01:04:00Z"),
            expectedOfferSignalColor = "YELLOW",
            expectedFarePerKmText = "R$ 1,98/km",
        )
    }

    @Test
    fun `evento 07 vira OFFER_CANDIDATE e não preserva snapshot acionável`() {
        configureReadyUber()
        val texts = loadFixtureTexts("driver/uber_event_07_offer_candidate.txt")
        val capturedAt = Instant.parse("2026-04-29T01:05:00Z")

        DriverStateManager.recordProviderEventAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_CONTENT_CHANGED",
            texts = texts,
            capturedAt = capturedAt,
        )
        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = texts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(texts),
            capturedAt = capturedAt,
        )

        val snapshot = DriverStateManager.snapshotAt(capturedAt.plusSeconds(1))

        assertEquals("OFFER_CANDIDATE", snapshot.currentContext.semanticState.code)
        assertFalse(snapshot.currentContext.isActionable)
        assertFalse(snapshot.lastOfferDetected)
        assertTrue(snapshot.structuredOfferPresent)
        assertEquals("OFFER_CANDIDATE", snapshot.offerClassification)
        assertEquals(false, snapshot.offerActionable)
        assertTrue(snapshot.offerMissingFields.contains("cta"))
        assertEquals("UberX", snapshot.structuredOffer?.productName)
        assertEquals("R\$ 37,37", snapshot.structuredOffer?.fareAmountText)
        assertTrue(snapshot.offerSignalPresent)
        assertEquals("RED", snapshot.offerSignalColor)
        assertEquals("R$ 1,56/km", snapshot.farePerKmText)
        assertTrue(snapshot.offerSignalWarnings.contains("CTA ausente."))
        assertTrue(snapshot.currentContext.semanticState.missingRequirements.contains("cta_forte"))
    }

    @Test
    fun `eventos expirados ou perdidos não viram acionáveis`() {
        configureReadyUber()
        val fixtures = listOf(
            "driver/uber_event_01_expired_or_missed.txt",
            "driver/uber_event_02_expired_or_missed.txt",
            "driver/uber_event_04_expired_or_missed.txt",
            "driver/uber_event_05_expired_or_missed.txt",
        )

        fixtures.forEachIndexed { index, resourceName ->
            DriverStateManager.resetForTest()
            configureReadyUber()
            val capturedAt = Instant.parse("2026-04-29T01:06:0${index}Z")
            val texts = loadFixtureTexts(resourceName)

            DriverStateManager.recordProviderEventAt(
                providerKey = "UBER_DRIVER",
                providerLabel = "Uber Driver",
                packageName = "com.ubercab.driver",
                eventType = "TYPE_WINDOW_CONTENT_CHANGED",
                texts = texts,
                capturedAt = capturedAt,
            )

            val snapshot = DriverStateManager.snapshotAt(capturedAt.plusSeconds(1))
            assertEquals("OFFER_EXPIRED_OR_MISSED", snapshot.currentContext.semanticState.code)
            assertFalse(snapshot.currentContext.isActionable)
            assertFalse(snapshot.lastOfferDetected)
            assertFalse(snapshot.structuredOfferPresent)
            assertFalse(snapshot.offerSignalPresent)
            assertEquals(null, snapshot.structuredOffer)
        }
    }

    @Test
    fun `oferta acionável vence contexto posterior de home online enquanto TTL seguir válido`() {
        configureReadyUber()
        val actionableTexts = loadFixtureTexts("driver/uber_event_06_actionable_offer.txt")
        val capturedAt = Instant.parse("2026-04-29T01:07:00Z")

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = actionableTexts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(actionableTexts),
            capturedAt = capturedAt,
        )
        DriverStateManager.recordProviderEventAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_CONTENT_CHANGED",
            texts = listOf(
                "Você está online",
                "Procurando viagens",
                "Página inicial",
                "1-4 min",
            ),
            capturedAt = capturedAt.plusSeconds(1),
        )

        val snapshot = DriverStateManager.snapshotAt(capturedAt.plusSeconds(2))

        assertTrue(snapshot.lastOfferDetected)
        assertEquals("ACTIONABLE_OFFER", snapshot.currentContext.semanticState.code)
        assertEquals("OFFER_SNAPSHOT_RETAINED", snapshot.currentContext.eventType)
        assertTrue(snapshot.currentContext.isActionable)
    }

    @Test
    fun `nova oferta válida substitui a oferta acionável anterior`() {
        configureReadyUber()
        val firstTexts = loadFixtureTexts("driver/uber_event_03_actionable_offer.txt")
        val secondTexts = loadFixtureTexts("driver/uber_event_08_actionable_offer.txt")
        val start = Instant.parse("2026-04-29T01:08:00Z")

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = firstTexts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(firstTexts),
            capturedAt = start,
        )
        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = secondTexts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(secondTexts),
            capturedAt = start.plusSeconds(2),
        )

        val snapshot = DriverStateManager.snapshotAt(start.plusSeconds(3))

        assertTrue(snapshot.lastOfferDetected)
        assertEquals("ACTIONABLE_OFFER", snapshot.lastOfferClassification)
        assertTrue(snapshot.lastOfferSummary?.contains("R\$ 6,93") == true)
    }

    @Test
    fun `provider diferente invalida última oferta antes do TTL`() {
        configureReadyUber()
        val texts = loadFixtureTexts("driver/uber_event_03_actionable_offer.txt")
        val start = Instant.parse("2026-04-29T01:09:00Z")

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = texts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(texts),
            capturedAt = start,
        )
        DriverStateManager.recordProviderEventAt(
            providerKey = "APP99_DRIVER",
            providerLabel = "99 Motorista",
            packageName = "com.app99.driver",
            eventType = "TYPE_WINDOW_STATE_CHANGED",
            texts = listOf("99 Motorista", "Tela inicial"),
            capturedAt = start.plusSeconds(2),
        )

        val snapshot = DriverStateManager.snapshotAt(start.plusSeconds(3))

        assertFalse(snapshot.lastOfferDetected)
        assertEquals("APP99_DRIVER", snapshot.currentContext.providerKey)
    }

    @Test
    fun `oferta expira após o TTL de retenção`() {
        configureReadyUber()
        val texts = loadFixtureTexts("driver/uber_event_06_actionable_offer.txt")
        val start = Instant.parse("2026-04-29T01:10:00Z")

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = texts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(texts),
            capturedAt = start,
        )

        val snapshot = DriverStateManager.snapshotAt(start.plusSeconds(19))

        assertFalse(snapshot.lastOfferDetected)
        assertEquals(null, snapshot.lastOfferClassification)
        assertTrue(snapshot.lastOfferMissingRequirements.isEmpty())
    }

    @Test
    fun `snapshot carrega preferencias do usuario e recalcula farol`() {
        configureReadyUber()
        DriverStateManager.updateSignalPreferences(
            DriverSignalPreferences.defaults().copy(
                minGreenFarePerKm = java.math.BigDecimal("1.90"),
                minGreenFarePerHour = java.math.BigDecimal("40.00"),
                source = "USER_CONFIGURED",
                updatedAt = "2026-04-29T02:00:00Z",
            ),
        )
        val texts = loadFixtureTexts("driver/uber_event_03_actionable_offer.txt")
        val start = Instant.parse("2026-04-29T02:00:00Z")

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = texts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(texts),
            capturedAt = start,
        )

        val snapshot = DriverStateManager.snapshotAt(start.plusSeconds(1))

        assertEquals("USER_CONFIGURED", snapshot.signalPreferences.source)
        assertEquals("GREEN", snapshot.offerSignalColor)
        assertEquals("R$ 42,94/h", snapshot.farePerHourText)
    }

    @Test
    fun `eventos fragmentados da oferta viram snapshot após agregação completa`() {
        configureReadyUber()
        val capturedAt = Instant.parse("2026-04-29T01:11:00Z")

        DriverStateManager.mergeOfferCandidateTextsAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            texts = listOf("UberX", "R\$ 37,37"),
            capturedAt = capturedAt,
        )
        DriverStateManager.mergeOfferCandidateTextsAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            texts = listOf(
                "5 min (2.0 km)",
                "Avenida Washington Luís, 483, Boqueirão, Santos",
            ),
            capturedAt = capturedAt.plusMillis(500),
        )
        val mergedTexts = DriverStateManager.mergeOfferCandidateTextsAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            texts = listOf("Selecionar"),
            capturedAt = capturedAt.plusSeconds(1),
        )

        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = mergedTexts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(mergedTexts),
            capturedAt = capturedAt.plusSeconds(1),
        )

        val snapshot = DriverStateManager.snapshotAt(capturedAt.plusSeconds(2))

        assertTrue(snapshot.lastOfferDetected)
        assertEquals("ACTIONABLE_OFFER", snapshot.currentContext.semanticState.code)
        assertTrue(snapshot.lastOfferSignals.any { it.contains("Selecionar") })
    }

    private fun assertActionableFixture(
        resourceName: String,
        expectedSignal: String,
        expectedProduct: String,
        capturedAt: Instant,
        expectedOfferSignalColor: String,
        expectedFarePerKmText: String,
    ) {
        configureReadyUber()
        val texts = loadFixtureTexts(resourceName)

        DriverStateManager.recordProviderEventAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_CONTENT_CHANGED",
            texts = texts,
            capturedAt = capturedAt,
        )
        DriverStateManager.recordOfferSnapshotAt(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            rawTexts = texts,
            detectedSignals = DriverOfferEventDetector.detectOfferSignals(texts),
            capturedAt = capturedAt,
        )

        val snapshot = DriverStateManager.snapshotAt(capturedAt.plusSeconds(1))

        assertTrue(snapshot.lastOfferDetected)
        assertEquals("ACTIONABLE_OFFER", snapshot.currentContext.semanticState.code)
        assertEquals("ACTIONABLE_OFFER", snapshot.lastOfferClassification)
        assertTrue(snapshot.currentContext.isActionable)
        assertTrue(snapshot.lastOfferSignals.any { it.contains(expectedSignal) })
        assertTrue(snapshot.lastOfferSignals.any { it.contains(expectedProduct) })
        assertEquals(true, snapshot.lastOfferActionable)
        assertTrue(snapshot.structuredOfferPresent)
        assertEquals("ACTIONABLE_OFFER", snapshot.offerClassification)
        assertEquals(true, snapshot.offerActionable)
        assertEquals(expectedProduct, snapshot.structuredOffer?.productName)
        assertEquals(expectedSignal, snapshot.structuredOffer?.fareAmountText)
        assertEquals("Selecionar", snapshot.structuredOffer?.ctaText)
        assertTrue(snapshot.offerSignalPresent)
        assertEquals(expectedOfferSignalColor, snapshot.offerSignalColor)
        assertEquals(expectedFarePerKmText, snapshot.farePerKmText)
        assertEquals(UberOfferSignalEvaluator.RULE_VERSION, snapshot.signalRuleVersion)
    }

    private fun configureReadyUber() {
        DriverStateManager.updateFoundation(
            packageName = "com.example.despesas_frontend",
            methodChannel = "com.gilrossi.despesas/driver_module",
            nativeBridgeAvailable = true,
            methodChannelReady = true,
            accessibilityServiceDeclared = true,
            accessibilityServiceEnabled = true,
            canOpenAccessibilitySettings = true,
            missingCapabilities = emptyList(),
            targetApps = listOf(
                DriverTargetAppSnapshot(
                    key = "UBER_DRIVER",
                    label = "Uber Driver",
                    packageName = "com.ubercab.driver",
                    installed = true,
                    enabledInSystem = true,
                    launchIntentAvailable = true,
                    appReady = true,
                    missingCapabilities = emptyList(),
                    detectedPackageName = "com.ubercab.driver",
                ),
            ),
            androidAutoPrepared = false,
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
