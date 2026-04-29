package com.example.despesas_frontend

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.example.despesas_frontend.driver.DriverModuleMethodChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private lateinit var driverModuleMethodChannelHandler: DriverModuleMethodChannelHandler

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "MainActivity onCreate")
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        Log.d(TAG, "MainActivity onStart")
        super.onStart()
    }

    override fun onResume() {
        Log.d(TAG, "MainActivity onResume")
        super.onResume()
    }

    override fun onPause() {
        Log.d(TAG, "MainActivity onPause")
        super.onPause()
    }

    override fun onStop() {
        Log.d(TAG, "MainActivity onStop")
        super.onStop()
    }

    override fun onDestroy() {
        Log.d(TAG, "MainActivity onDestroy")
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        Log.d(TAG, "MainActivity onNewIntent")
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        Log.d(TAG, "MainActivity provideFlutterEngine")
        super.configureFlutterEngine(flutterEngine)
        driverModuleMethodChannelHandler = DriverModuleMethodChannelHandler(applicationContext)
        driverModuleMethodChannelHandler.register(flutterEngine)
        Log.d(TAG, "FlutterEngine attached")
    }

    override fun onFlutterUiDisplayed() {
        Log.d(TAG, "MainActivity onFlutterUiDisplayed")
        super.onFlutterUiDisplayed()
    }

    override fun onFlutterUiNoLongerDisplayed() {
        Log.d(TAG, "MainActivity onFlutterUiNoLongerDisplayed")
        super.onFlutterUiNoLongerDisplayed()
    }
}
