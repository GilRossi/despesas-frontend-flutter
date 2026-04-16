package com.example.despesas_frontend.driver

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class DriverAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Foundation only. Event automation starts in a later round.
    }

    override fun onInterrupt() {
        // Foundation only. No interruption handling is needed yet.
    }
}
