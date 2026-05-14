import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLockNative {
  static const _channel = MethodChannel('com.nappu/app_lock');

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> hasUsageStatsPermission() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestUsageStatsPermission() async {
    if (!isAndroid) return;
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  static Future<bool> hasOverlayPermission() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    if (!isAndroid) return;
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<bool> startAppLock(
    List<String> packages, {
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('startAppLock', {
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

  static Future<bool> stopAppLock() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('stopAppLock') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAppLockRunning() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAppLockRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

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

  static Future<bool> emergencyOverride({int durationMs = 900000}) async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('emergencyOverride', {'durationMs': durationMs}) ?? false;
    } catch (_) {
      return false;
    }
  }
}
