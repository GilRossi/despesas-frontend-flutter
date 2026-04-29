package com.example.despesas_frontend.driver

internal object DriverOfferTraceLogger {
    private const val TAG = "DriverOfferTrace"

    fun d(message: String) {
        try {
            android.util.Log.d(TAG, message)
        } catch (_: Throwable) {
            println("$TAG $message")
        }
    }
}
