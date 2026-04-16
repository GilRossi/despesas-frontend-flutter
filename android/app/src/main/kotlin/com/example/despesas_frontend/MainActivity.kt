package com.example.despesas_frontend

import androidx.annotation.NonNull
import com.example.despesas_frontend.driver.DriverModuleMethodChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var driverModuleMethodChannelHandler: DriverModuleMethodChannelHandler

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        driverModuleMethodChannelHandler = DriverModuleMethodChannelHandler(applicationContext)
        driverModuleMethodChannelHandler.register(flutterEngine)
    }
}
