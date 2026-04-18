package com.example.despesas_frontend.driver

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityEvent
import java.util.LinkedHashSet

class DriverAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val safeEvent = event ?: return
        val packageName = safeEvent.packageName?.toString() ?: return
        val provider = monitoredProvider(packageName)
        if (provider == null) {
            DriverStateManager.markProviderOutOfFocus(packageName)
            return
        }
        val eventType = eventTypeName(safeEvent.eventType) ?: return

        val visibleTexts = LinkedHashSet<String>()
        addCandidate(
            visibleTexts,
            safeEvent.className
                ?.toString()
                ?.substringAfterLast('.')
                ?.trim(),
        )
        safeEvent.text
            ?.mapNotNull { candidate -> candidate?.toString()?.trim() }
            ?.forEach { candidate -> addCandidate(visibleTexts, candidate) }
        addCandidate(visibleTexts, safeEvent.contentDescription?.toString()?.trim())
        val source = safeEvent.source
        try {
            collectNodeTexts(source, visibleTexts)
        } finally {
            source?.recycle()
        }
        collectWindowContext(packageName, visibleTexts)
        collectNodeTexts(rootInActiveWindow, visibleTexts)

        DriverStateManager.recordProviderEvent(
            providerKey = provider.key,
            providerLabel = provider.label,
            packageName = packageName,
            eventType = eventType,
            texts = visibleTexts.toList(),
        )
    }

    override fun onInterrupt() {
        // No-op. This round only captures passive local context.
    }

    private fun monitoredProvider(packageName: String): DriverModuleMethodChannelHandler.DriverTargetApp? {
        return MONITORED_PROVIDERS.firstOrNull { provider ->
            provider.packageCandidates.any { candidate ->
                candidate.equals(packageName, ignoreCase = true)
            }
        }
    }

    private fun eventTypeName(eventType: Int): String? {
        return when (eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "TYPE_WINDOW_STATE_CHANGED"
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "TYPE_WINDOW_CONTENT_CHANGED"
            else -> null
        }
    }

    private fun collectNodeTexts(
        node: AccessibilityNodeInfo?,
        collector: LinkedHashSet<String>,
        limit: Int = 12,
    ) {
        if (node == null || collector.size >= limit) {
            return
        }

        addCandidate(collector, node.text?.toString()?.trim())
        addCandidate(collector, node.contentDescription?.toString()?.trim())

        for (index in 0 until node.childCount) {
            if (collector.size >= limit) {
                break
            }
            val child = node.getChild(index)
            try {
                collectNodeTexts(child, collector, limit)
            } finally {
                child?.recycle()
            }
        }
    }

    private fun collectWindowContext(
        packageName: String,
        collector: LinkedHashSet<String>,
        limit: Int = 12,
    ) {
        for (window in windows) {
            if (collector.size >= limit) {
                return
            }

            val root = window.root
            try {
                val rootPackageName = root?.packageName?.toString()
                if (!rootPackageName.equals(packageName, ignoreCase = true)) {
                    continue
                }
                addCandidate(collector, window.title?.toString()?.trim())
                collectNodeTexts(root, collector, limit)
            } finally {
                root?.recycle()
            }
        }
    }

    private fun addCandidate(
        collector: LinkedHashSet<String>,
        candidate: String?,
    ) {
        if (candidate.isNullOrBlank()) {
            return
        }
        val normalized = candidate.trim()
        if (normalized.length < 2 || normalized.length > 120) {
            return
        }
        collector += normalized
    }

    companion object {
        private val MONITORED_PROVIDERS = listOf(
            DriverModuleMethodChannelHandler.DriverTargetApp(
                key = "UBER_DRIVER",
                label = "Uber Driver",
                packageCandidates = listOf("com.ubercab.driver"),
            ),
            DriverModuleMethodChannelHandler.DriverTargetApp(
                key = "APP99_DRIVER",
                label = "99 Motorista",
                packageCandidates = listOf("com.app99.driver"),
            ),
        )
    }
}
