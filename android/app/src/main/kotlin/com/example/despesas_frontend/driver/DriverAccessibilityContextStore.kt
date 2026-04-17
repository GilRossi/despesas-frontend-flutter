package com.example.despesas_frontend.driver

object DriverAccessibilityContextStore {
    private val contextsByProvider = linkedMapOf<String, DriverProviderContextSnapshot>()

    @Synchronized
    fun upsert(snapshot: DriverProviderContextSnapshot) {
        val previous = contextsByProvider[snapshot.providerKey]
        if (previous != null &&
            previous.packageName == snapshot.packageName &&
            previous.eventType == snapshot.eventType &&
            previous.texts == snapshot.texts
        ) {
            return
        }
        contextsByProvider[snapshot.providerKey] = snapshot
    }

    @Synchronized
    fun snapshots(): List<DriverProviderContextSnapshot> {
        return contextsByProvider.values.toList()
    }
}
