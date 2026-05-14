package com.example.nappu_app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nappu/app_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccessibilityPermission" -> {
                    result.success(isAccessibilityEnabled())
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "isAppLockRunning" -> {
                    result.success(AppLockAccessibilityService.isRunning)
                }
                "updateAppLockConfig" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val startHour = call.argument<Int>("startHour") ?: 22
                    val startMinute = call.argument<Int>("startMinute") ?: 30
                    val endHour = call.argument<Int>("endHour") ?: 7
                    val endMinute = call.argument<Int>("endMinute") ?: 0
                    AppLockAccessibilityService.updateConfig(
                        this, packages, startHour, startMinute, endHour, endMinute
                    )
                    result.success(true)
                }
                "setAppLockEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    AppLockAccessibilityService.setEnabled(this, enabled)
                    result.success(true)
                }
                "emergencyOverride" -> {
                    val durationMs = call.argument<Int>("durationMs") ?: 900000
                    val until = System.currentTimeMillis() + durationMs
                    AppLockAccessibilityService.setOverrideUntil(this, until)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabled = am.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC
        )
        return enabled.any {
            it.resolveInfo.serviceInfo.name == AppLockAccessibilityService::class.java.name
        }
    }
}
