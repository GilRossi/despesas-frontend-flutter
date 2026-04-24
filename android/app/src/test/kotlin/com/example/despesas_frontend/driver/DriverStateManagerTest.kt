package com.example.despesas_frontend.driver

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DriverStateManagerTest {
    @After
    fun tearDown() {
        DriverStateManager.resetForTest()
    }

    @Test
    fun `classifica Uber com alta demanda como contexto relevante`() {
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

        DriverStateManager.recordProviderEvent(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_CONTENT_CHANGED",
            texts = listOf(
                "Tudo pronto para fazer entregas",
                "Alta demanda aqui",
                "A demanda está alta e o tempo de espera baixo.",
                "+R$ 3,50",
                "Descubra as oportunidades",
            ),
        )

        val snapshot = DriverStateManager.snapshot()

        assertEquals("RELEVANT_CONTEXT", snapshot.currentContext.semanticState.code)
        assertEquals("GREEN", snapshot.signal.color)
        assertTrue(snapshot.currentContext.semanticState.summary.contains("Alta demanda aqui"))
        assertTrue(snapshot.currentContext.semanticState.summary.contains("+R$ 3,50"))
    }

    @Test
    fun `classifica 99 com permissao de localizacao como login ou consentimento`() {
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
                    key = "APP99_DRIVER",
                    label = "99 Motorista",
                    packageName = "com.app99.driver",
                    installed = true,
                    enabledInSystem = true,
                    launchIntentAvailable = true,
                    appReady = true,
                    missingCapabilities = emptyList(),
                    detectedPackageName = "com.app99.driver",
                ),
            ),
            androidAutoPrepared = false,
        )

        DriverStateManager.recordProviderEvent(
            providerKey = "APP99_DRIVER",
            providerLabel = "99 Motorista",
            packageName = "com.app99.driver",
            eventType = "TYPE_WINDOW_STATE_CHANGED",
            texts = listOf(
                "Configure as permissões de localização como “Sempre permitir”",
                "Isso ajudará a evitar cálculo incorreto de tarifas, local de embarque impreciso e solicitações de corridas muito distantes.",
                "Permitir",
                "Cancelar",
            ),
        )

        val snapshot = DriverStateManager.snapshot()

        assertEquals("LOGIN_OR_CONSENT", snapshot.currentContext.semanticState.code)
        assertEquals("YELLOW", snapshot.signal.color)
        assertTrue(snapshot.currentContext.semanticState.summary.contains("Sempre permitir"))
    }

    @Test
    fun `classifica Uber na tela principal sem oferta como home`() {
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

        DriverStateManager.recordProviderEvent(
            providerKey = "UBER_DRIVER",
            providerLabel = "Uber Driver",
            packageName = "com.ubercab.driver",
            eventType = "TYPE_WINDOW_STATE_CHANGED",
            texts = listOf(
                "Tudo pronto para fazer entregas",
                "Página inicial",
                "Ganhos",
                "Mensagens",
                "Menu",
            ),
        )

        val snapshot = DriverStateManager.snapshot()

        assertEquals("HOME", snapshot.currentContext.semanticState.code)
        assertEquals("YELLOW", snapshot.signal.color)
        assertTrue(snapshot.currentContext.semanticState.summary.contains("Página inicial"))
    }
}
