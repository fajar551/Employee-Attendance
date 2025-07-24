package com.example.dmeo_prj

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "developer_mode_check").setMethodCallHandler {
            call, result ->
            if (call.method == "isDeveloperMode") {
                val isDevMode = try {
                    Settings.Secure.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
                } catch (e: Exception) {
                    false
                }
                result.success(isDevMode)
            } else {
                result.notImplemented()
            }
        }
    }
}
