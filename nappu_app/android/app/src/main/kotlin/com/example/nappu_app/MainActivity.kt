package com.example.nappu_app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nappu/app_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }
                "startAppLock" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val startHour = call.argument<Int>("startHour") ?: 22
                    val startMinute = call.argument<Int>("startMinute") ?: 30
                    val endHour = call.argument<Int>("endHour") ?: 7
                    val endMinute = call.argument<Int>("endMinute") ?: 0
                    AppLockService.updateConfig(this, packages, startHour, startMinute, endHour, endMinute)
                    val serviceIntent = Intent(this, AppLockService::class.java)
                    ContextCompat.startForegroundService(this, serviceIntent)
                    result.success(true)
                }
                "stopAppLock" -> {
                    val serviceIntent = Intent(this, AppLockService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                "isAppLockRunning" -> {
                    result.success(AppLockService.isRunning)
                }
                "updateAppLockConfig" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val startHour = call.argument<Int>("startHour") ?: 22
                    val startMinute = call.argument<Int>("startMinute") ?: 30
                    val endHour = call.argument<Int>("endHour") ?: 7
                    val endMinute = call.argument<Int>("endMinute") ?: 0
                    AppLockService.updateConfig(this, packages, startHour, startMinute, endHour, endMinute)
                    result.success(true)
                }
                "emergencyOverride" -> {
                    val durationMs = call.argument<Int>("durationMs") ?: 900000
                    AppLockService.overrideUntil = System.currentTimeMillis() + durationMs
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
