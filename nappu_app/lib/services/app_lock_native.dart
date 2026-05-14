import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLockNative {
  static const _channel = MethodChannel('com.nappu/app_lock');

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  // ─── Accessibility permission ─────────────────────────

  static Future<bool> hasAccessibilityPermission() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasAccessibilityPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    if (!isAndroid) return;
    await _channel.invokeMethod('requestAccessibilityPermission');
  }

  // ─── Service status ───────────────────────────────────

  static Future<bool> isAppLockRunning() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAppLockRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Config (writes to SharedPreferences) ─────────────

  static Future<bool> updateAppLockConfig(
    List<String> packages, {
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('updateAppLockConfig', {
        'packages': packages,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      }) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setAppLockEnabled(bool enabled) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('setAppLockEnabled', {
        'enabled': enabled,
      }) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> emergencyOverride({int durationMs = 900000}) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('emergencyOverride', {'durationMs': durationMs}) ?? false;
    } catch (_) {
      return false;
    }
  }
}
