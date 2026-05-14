package com.example.nappu_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AppLockService : Service() {

    companion object {
        private const val CHANNEL_ID = "nappu_app_lock"
        private const val NOTIFICATION_ID = 1001
        private const val POLL_INTERVAL_MS = 500L      // during lock window
        private const val IDLE_INTERVAL_MS = 60_000L  // outside lock window
        private const val PREFS_NAME = "nappu_app_lock"
        private const val KEY_PACKAGES = "packages"
        private const val KEY_START_HOUR = "startHour"
        private const val KEY_START_MINUTE = "startMinute"
        private const val KEY_END_HOUR = "endHour"
        private const val KEY_END_MINUTE = "endMinute"

        var lockedPackages: MutableSet<String> = mutableSetOf()
        var isRunning = false
        var overrideUntil: Long = 0
        var lockStartHour = 22
        var lockStartMinute = 30
        var lockEndHour = 7
        var lockEndMinute = 0

        fun updateConfig(
            context: Context,
            packages: List<String>,
            startHour: Int,
            startMinute: Int,
            endHour: Int,
            endMinute: Int
        ) {
            lockedPackages = packages.toMutableSet()
            lockStartHour = startHour
            lockStartMinute = startMinute
            lockEndHour = endHour
            lockEndMinute = endMinute
            prefs(context).edit()
                .putString(KEY_PACKAGES, packages.joinToString(","))
                .putInt(KEY_START_HOUR, startHour)
                .putInt(KEY_START_MINUTE, startMinute)
                .putInt(KEY_END_HOUR, endHour)
                .putInt(KEY_END_MINUTE, endMinute)
                .apply()
        }

        fun loadConfig(context: Context) {
            val prefs = prefs(context)
            val packages = prefs.getString(KEY_PACKAGES, "") ?: ""
            lockedPackages = packages.split(",").filter { it.isNotBlank() }.toMutableSet()
            lockStartHour = prefs.getInt(KEY_START_HOUR, 22)
            lockStartMinute = prefs.getInt(KEY_START_MINUTE, 30)
            lockEndHour = prefs.getInt(KEY_END_HOUR, 7)
            lockEndMinute = prefs.getInt(KEY_END_MINUTE, 0)
        }

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var currentlyBlocked: String? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (isWithinLockWindow()) {
                checkForegroundApp()
                handler.postDelayed(this, POLL_INTERVAL_MS)
            } else {
                // Outside lock window — clean up and sleep until next check
                if (currentlyBlocked != null) {
                    removeOverlay()
                    currentlyBlocked = null
                }
                handler.postDelayed(this, IDLE_INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadConfig(this)
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(pollRunnable)
        removeOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkForegroundApp() {
        if (System.currentTimeMillis() < overrideUntil) {
            removeOverlay()
            return
        }

        val foreground = getForegroundPackage()
        if (foreground != null && lockedPackages.contains(foreground)) {
            if (currentlyBlocked != foreground) {
                showOverlay(foreground)
                currentlyBlocked = foreground
            }
        } else {
            if (currentlyBlocked != null) {
                removeOverlay()
                currentlyBlocked = null
            }
        }
    }

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 2000, now)
        var foreground: String? = null
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                foreground = event.packageName
            }
        }
        return foreground
    }

    private fun isWithinLockWindow(): Boolean {
        val calendar = java.util.Calendar.getInstance()
        val now = calendar.get(java.util.Calendar.HOUR_OF_DAY) * 60 + calendar.get(java.util.Calendar.MINUTE)
        val start = lockStartHour * 60 + lockStartMinute
        val end = lockEndHour * 60 + lockEndMinute
        return if (start == end) {
            true
        } else if (start < end) {
            now in start until end
        } else {
            now >= start || now < end
        }
    }

    private fun showOverlay(packageName: String) {
        removeOverlay()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#F00A0E1A"))
            setPadding(60, 60, 60, 60)
        }

        val emoji = TextView(this).apply {
            text = "\uD83D\uDC11"
            textSize = 64f
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "Time to Sleep!"
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(this).apply {
            text = "This app is locked during your bedtime.\nOpen Nappu to use an emergency override."
            textSize = 14f
            setTextColor(Color.parseColor("#8E94B0"))
            gravity = Gravity.CENTER
        }

        layout.addView(emoji)
        layout.addView(title)
        layout.addView(subtitle)

        overlayView = layout
        windowManager?.addView(layout, params)
    }

    private fun removeOverlay() {
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (_: Exception) {}
            overlayView = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Lock",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Nappu app lock is active"
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nappu App Lock")
            .setContentText("Protecting your sleep time")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
