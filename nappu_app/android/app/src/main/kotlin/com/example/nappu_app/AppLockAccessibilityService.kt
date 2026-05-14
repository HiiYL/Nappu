package com.example.nappu_app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.LinearLayout
import android.widget.TextView

class AppLockAccessibilityService : AccessibilityService() {

    companion object {
        private const val PREFS_NAME = "nappu_app_lock"
        private const val KEY_PACKAGES = "packages"
        private const val KEY_START_HOUR = "startHour"
        private const val KEY_START_MINUTE = "startMinute"
        private const val KEY_END_HOUR = "endHour"
        private const val KEY_END_MINUTE = "endMinute"
        private const val KEY_OVERRIDE_UNTIL = "overrideUntil"
        private const val KEY_ENABLED = "lockEnabled"

        // Delay before removing overlay — lets transient window events
        // (launcher exit animation, framework dialogs) settle before we
        // decide the user truly left the locked app.
        private const val REMOVAL_DELAY_MS = 350L

        var isRunning = false
            private set

        fun updateConfig(
            context: Context,
            packages: List<String>,
            startHour: Int,
            startMinute: Int,
            endHour: Int,
            endMinute: Int
        ) {
            prefs(context).edit()
                .putString(KEY_PACKAGES, packages.joinToString(","))
                .putInt(KEY_START_HOUR, startHour)
                .putInt(KEY_START_MINUTE, startMinute)
                .putInt(KEY_END_HOUR, endHour)
                .putInt(KEY_END_MINUTE, endMinute)
                .apply()
        }

        fun setOverrideUntil(context: Context, until: Long) {
            prefs(context).edit().putLong(KEY_OVERRIDE_UNTIL, until).apply()
        }

        fun setEnabled(context: Context, enabled: Boolean) {
            prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
        }

        fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var currentlyBlocked: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private var pendingRemoval: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        isRunning = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return

        // ── Ignore windows that don't represent real app switches ──

        // Our own package: the overlay we add via WindowManager fires
        // TYPE_WINDOW_STATE_CHANGED too. Reacting to it creates an
        // infinite show→remove→show loop. Always ignore.
        if (packageName == this.packageName) return

        // System UI: task manager, notification shade, status bar
        if (packageName == "com.android.systemui") return

        // Keyboard / input method windows
        if (className.contains("InputMethod", ignoreCase = true) ||
            className.contains("SoftInput", ignoreCase = true)) return

        // Android framework popups (permission dialogs, ANR dialogs, toasts)
        if (packageName == "android" && !className.endsWith("Activity")) return

        // ── Check if locking should be active ──

        val prefs = prefs(this)

        if (!prefs.getBoolean(KEY_ENABLED, false)) {
            scheduleOverlayRemoval()
            return
        }

        val overrideUntil = prefs.getLong(KEY_OVERRIDE_UNTIL, 0)
        if (System.currentTimeMillis() < overrideUntil) {
            scheduleOverlayRemoval()
            return
        }

        if (!isWithinLockWindow(prefs)) {
            scheduleOverlayRemoval()
            return
        }

        // ── Locked-app check ──

        val lockedPackages = (prefs.getString(KEY_PACKAGES, "") ?: "")
            .split(",").filter { it.isNotBlank() }.toSet()

        if (lockedPackages.contains(packageName)) {
            // Locked app detected — show overlay immediately and cancel any
            // pending removal (e.g. from a transient launcher animation event
            // that fired a few ms earlier during the app launch sequence).
            cancelPendingRemoval()
            if (currentlyBlocked != packageName) {
                showOverlay(packageName)
                currentlyBlocked = packageName
            }
        } else {
            // Non-locked app — schedule removal with a delay so that transient
            // intermediate windows during app-launch animations don't cause
            // the overlay to flicker off and on.
            scheduleOverlayRemoval()
        }
    }

    override fun onInterrupt() {
        cancelPendingRemoval()
        removeOverlay()
        currentlyBlocked = null
    }

    override fun onDestroy() {
        isRunning = false
        cancelPendingRemoval()
        removeOverlay()
        super.onDestroy()
    }

    // ── Debounced removal ──────────────────────────────────────────────

    private fun scheduleOverlayRemoval() {
        if (currentlyBlocked == null && overlayView == null) return
        cancelPendingRemoval()
        pendingRemoval = Runnable {
            removeOverlay()
            currentlyBlocked = null
            pendingRemoval = null
        }
        handler.postDelayed(pendingRemoval!!, REMOVAL_DELAY_MS)
    }

    private fun cancelPendingRemoval() {
        pendingRemoval?.let { handler.removeCallbacks(it) }
        pendingRemoval = null
    }

    private fun isWithinLockWindow(prefs: SharedPreferences): Boolean {
        val calendar = java.util.Calendar.getInstance()
        val now = calendar.get(java.util.Calendar.HOUR_OF_DAY) * 60 +
                calendar.get(java.util.Calendar.MINUTE)
        val start = prefs.getInt(KEY_START_HOUR, 22) * 60 + prefs.getInt(KEY_START_MINUTE, 30)
        val end = prefs.getInt(KEY_END_HOUR, 7) * 60 + prefs.getInt(KEY_END_MINUTE, 0)
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

        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
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
                performGlobalAction(GLOBAL_ACTION_HOME)
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
                val intent = packageManager.getLaunchIntentForPackage(this@AppLockAccessibilityService.packageName)
                intent?.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }

        buttonRow.addView(goHomeButton)
        buttonRow.addView(android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(12), 0)
        })
        buttonRow.addView(openNappuButton)

        layout.addView(emoji)
        layout.addView(title)
        layout.addView(subtitle)

        // Spacer
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
}
