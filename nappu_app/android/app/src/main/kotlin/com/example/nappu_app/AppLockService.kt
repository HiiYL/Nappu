package com.example.nappu_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AppLockService : Service() {

    companion object {
        private const val CHANNEL_ID = "nappu_app_lock"
        private const val NOTIFICATION_ID = 1001
        private const val POLL_INTERVAL_MS = 500L
        private const val PREFS_NAME = "nappu_app_lock"
        private const val KEY_PACKAGES = "packages"
        private const val KEY_START_HOUR = "startHour"
        private const val KEY_START_MINUTE = "startMinute"
        private const val KEY_END_HOUR = "endHour"
        private const val KEY_END_MINUTE = "endMinute"

        var lockedPackages: MutableSet<String> = mutableSetOf()
        var isRunning = false
        var overrideUntil: Long = 0
        private const val KEY_OVERRIDE_UNTIL = "overrideUntil"
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
            overrideUntil = prefs.getLong(KEY_OVERRIDE_UNTIL, 0)
        }

        fun setOverrideUntil(context: Context, until: Long) {
            overrideUntil = until
            prefs(context).edit().putLong(KEY_OVERRIDE_UNTIL, until).apply()
        }

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var currentlyBlocked: String? = null
    private var screenOn = true
    private var lastForeground: String? = null      // for skip-duplicate optimisation
    private var lastKnownForeground: String? = null  // persists across empty queryEvents windows

    // Pause polling when screen is off — user can't launch apps with screen off
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    screenOn = false
                    handler.removeCallbacks(pollRunnable)
                }
                Intent.ACTION_SCREEN_ON -> {
                    screenOn = true
                    lastForeground = null        // force re-check on wake
                    lastKnownForeground = null   // force fresh detection
                    handler.removeCallbacks(pollRunnable)
                    handler.post(pollRunnable)
                }
            }
        }
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!screenOn) return

            if (isWithinLockWindow()) {
                checkForegroundApp()
                handler.postDelayed(this, POLL_INTERVAL_MS)
            } else {
                // Outside lock window — clean up and sleep until window starts
                if (currentlyBlocked != null) {
                    removeOverlay()
                    currentlyBlocked = null
                }
                val delay = msUntilLockWindow()
                if (delay > 0) handler.postDelayed(this, delay)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)

        // Initialise screen state
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        screenOn = pm.isInteractive
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadConfig(this)
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true
        handler.removeCallbacks(pollRunnable)
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(pollRunnable)
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        removeOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkForegroundApp() {
        if (System.currentTimeMillis() < overrideUntil) {
            if (currentlyBlocked != null) {
                removeOverlay()
                currentlyBlocked = null
            }
            return
        }

        val foreground = getForegroundPackage() ?: return

        // Skip if foreground hasn't changed (avoid redundant work)
        if (foreground == lastForeground && currentlyBlocked != null && lockedPackages.contains(foreground)) return
        if (foreground == lastForeground && currentlyBlocked == null && !lockedPackages.contains(foreground)) return
        lastForeground = foreground

        if (lockedPackages.contains(foreground)) {
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
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return lastKnownForeground
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 5000, now)
        var foreground: String? = null
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                foreground = event.packageName
            }
        }
        if (foreground != null) {
            // Ignore own package — our overlay/app shouldn't count
            if (foreground != packageName) lastKnownForeground = foreground
        }
        return lastKnownForeground
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

    private fun msUntilLockWindow(): Long {
        val cal = java.util.Calendar.getInstance()
        val nowMin = cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + cal.get(java.util.Calendar.MINUTE)
        val start = lockStartHour * 60 + lockStartMinute
        val diffMin = if (start > nowMin) start - nowMin else (1440 - nowMin) + start
        val nowSec = cal.get(java.util.Calendar.SECOND)
        return (diffMin * 60L - nowSec) * 1000L
    }

    private fun showOverlay(packageName: String) {
        removeOverlay()

        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#F00A0E1A"))
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }

        val nappuImage = ImageView(this).apply {
            setImageResource(R.drawable.nappu_lock)
            adjustViewBounds = true
            scaleType = ImageView.ScaleType.FIT_CENTER
            layoutParams = LinearLayout.LayoutParams(dp(116), dp(132)).apply {
                bottomMargin = dp(12)
            }
        }

        val title = TextView(this).apply {
            text = "Time to Sleep!"
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(this).apply {
            text = "This app is locked during your bedtime.\nPut down your phone — Nappu believes in you!"
            textSize = 14f
            setTextColor(Color.parseColor("#8E94B0"))
            gravity = Gravity.CENTER
        }

        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        val goHomeButton = TextView(this).apply {
            text = "Go Home"
            textSize = 15f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(12), dp(28), dp(12))
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor("#2A2F45"))
                cornerRadius = dp(12).toFloat()
            }
            setOnClickListener {
                removeOverlay()
                currentlyBlocked = null
                lastForeground = null
                lastKnownForeground = null
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            }
        }

        val openNappuButton = TextView(this).apply {
            text = "Open Nappu"
            textSize = 15f
            setTextColor(Color.parseColor("#7C8AE6"))
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(12), dp(28), dp(12))
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor("#1E2236"))
                cornerRadius = dp(12).toFloat()
                setStroke(dp(1), Color.parseColor("#7C8AE6"))
            }
            setOnClickListener {
                removeOverlay()
                currentlyBlocked = null
                lastForeground = null
                lastKnownForeground = null
                val intent = packageManager.getLaunchIntentForPackage(this@AppLockService.packageName)
                intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }

        buttonRow.addView(goHomeButton)
        buttonRow.addView(android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(12), 0)
        })
        buttonRow.addView(openNappuButton)

        layout.addView(nappuImage)
        layout.addView(title)
        layout.addView(subtitle)
        layout.addView(android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(32)
            )
        })
        layout.addView(buttonRow)

        overlayView = layout
        try {
            windowManager?.addView(layout, params)
        } catch (_: Exception) {}
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
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nappu App Lock")
            .setContentText("Protecting your sleep time")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }
}
