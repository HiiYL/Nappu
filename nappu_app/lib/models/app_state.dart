import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/app_lock_native.dart';

class SleepLog {
  final DateTime date;
  final String quality;
  final int bedtimeHour;
  final int wakeupHour;
  final double duration;

  SleepLog({
    required this.date,
    required this.quality,
    required this.bedtimeHour,
    required this.wakeupHour,
    required this.duration,
  });
}

class LockedApp {
  final String name;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  String status;

  LockedApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    required this.status,
  });
}

class ShopItem {
  final String name;
  final String emoji;
  final int price;
  final bool owned;
  final bool equipped;

  ShopItem({
    required this.name,
    required this.emoji,
    required this.price,
    this.owned = false,
    this.equipped = false,
  });

  ShopItem copyWith({bool? owned, bool? equipped}) {
    return ShopItem(
      name: name,
      emoji: emoji,
      price: price,
      owned: owned ?? this.owned,
      equipped: equipped ?? this.equipped,
    );
  }
}

// Emoji lookup for shop items (static catalog)
const Map<String, String> _itemEmojis = {
  'Top Hat': '🎩', 'Cap': '🧢', 'Crown': '👑', 'Flower': '🌸',
  'Helmet': '🪖', 'Grad Cap': '🎓', 'Bear Ear': '🧸', 'Halo': '✨',
  'Pajamas': '👕', 'Sweater': '🧥', 'Cape': '🦸', 'Scarf': '🧣',
  'Pillow': '🛏️', 'Blanket': '🛋️', 'Teddy': '🧸', 'Moon Lamp': '🌙',
  'Night Sky': '🌙', 'Sakura': '🌸', 'Mountain': '⛰️',
};

const Map<String, int> _itemPrices = {
  'Top Hat': 0, 'Cap': 0, 'Crown': 120, 'Flower': 80,
  'Helmet': 90, 'Grad Cap': 100, 'Bear Ear': 60, 'Halo': 200,
  'Pajamas': 0, 'Sweater': 100, 'Cape': 150, 'Scarf': 70,
  'Pillow': 50, 'Blanket': 80, 'Teddy': 60, 'Moon Lamp': 120,
  'Night Sky': 0, 'Sakura': 0, 'Mountain': 150,
};

// Icon/color lookup for locked apps
final Map<String, IconData> appIconCatalog = {
  'Instagram': Icons.camera_alt,
  'TikTok': Icons.music_note,
  'WhatsApp': Icons.chat_bubble,
  'YouTube': Icons.play_arrow,
  'Twitter / X': Icons.tag,
  'Snapchat': Icons.flash_on,
  'Reddit': Icons.forum,
  'Facebook': Icons.facebook,
  'Telegram': Icons.send,
  'Discord': Icons.headset_mic,
  'Netflix': Icons.tv,
  'Twitch': Icons.videogame_asset,
};
final Map<String, Color> appColorCatalog = {
  'Instagram': const Color(0xFFe1306c),
  'TikTok': const Color(0xFF69c9d0),
  'WhatsApp': const Color(0xFF25d366),
  'YouTube': const Color(0xFFff0000),
  'Twitter / X': const Color(0xFF1da1f2),
  'Snapchat': const Color(0xFFfffc00),
  'Reddit': const Color(0xFFff4500),
  'Facebook': const Color(0xFF1877f2),
  'Telegram': const Color(0xFF0088cc),
  'Discord': const Color(0xFF5865f2),
  'Netflix': const Color(0xFFe50914),
  'Twitch': const Color(0xFF9146ff),
};
final Map<String, String> _appPackages = {
  // kept private — only used internally
  'Instagram': 'com.instagram.android',
  'TikTok': 'com.zhiliaoapp.musically',
  'WhatsApp': 'com.whatsapp',
  'YouTube': 'com.google.android.youtube',
  'Twitter / X': 'com.twitter.android',
  'Snapchat': 'com.snapchat.android',
  'Reddit': 'com.reddit.frontpage',
  'Facebook': 'com.facebook.katana',
  'Telegram': 'org.telegram.messenger',
  'Discord': 'com.discord',
  'Netflix': 'com.netflix.mediaclient',
  'Twitch': 'tv.twitch.android.app',
};

class AppState extends ChangeNotifier {
  bool isLoading = true;
  bool isFirstLaunch = false;
  String? errorMessage;

  String userName = 'User';
  int tokens = 0;
  int streak = 0;
  int nappuLevel = 1;
  int nappuXp = 0;
  int nappuMaxXp = 1000;
  String nappuMood = 'happy';
  double lastNightSleep = 0;
  int sleepQualityPercent = 0;
  String biweeklyInsight = '';

  List<Map<String, dynamic>> sleepTasks = [];
  List<Map<String, dynamic>> weeklyData = [];

  bool lockEnabled = true;
  int lockStartHour = 22;
  int lockStartMinute = 30;
  int lockEndHour = 7;
  int lockEndMinute = 0;
  List<LockedApp> lockedApps = [];

  String selectedCategory = 'Hats';
  List<ShopItem> hats = [];
  List<ShopItem> outfits = [];
  List<ShopItem> accessories = [];
  List<Map<String, dynamic>> roomThemes = [];

  String currentSleepQuality = 'Good';
  TimeOfDay currentBedtime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay currentWakeup = const TimeOfDay(hour: 6, minute: 0);
  bool hasLoggedToday = false;

  // ─── Computed getters ──────────────────────────────────

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  double get weeklyAvgSleep {
    final logged = weeklyData.where((d) => (d['hours'] as double) > 0).toList();
    if (logged.isEmpty) return 0;
    return logged.map((d) => d['hours'] as double).reduce((a, b) => a + b) / logged.length;
  }

  String get sleepDeltaText {
    if (lastNightSleep == 0 || weeklyAvgSleep == 0) return '';
    final delta = lastNightSleep - weeklyAvgSleep;
    final abs = delta.abs().toStringAsFixed(1);
    if (delta > 0.05) return '↑ +$abs from avg';
    if (delta < -0.05) return '↓ -$abs from avg';
    return '— on average';
  }

  Color get sleepDeltaColor {
    if (lastNightSleep == 0 || weeklyAvgSleep == 0) return const Color(0xFF8e94b0);
    final delta = lastNightSleep - weeklyAvgSleep;
    return delta >= 0 ? const Color(0xFF4cd964) : const Color(0xFFff4757);
  }

  String get qualityLabel {
    if (sleepQualityPercent >= 90) return 'Great sleep!';
    if (sleepQualityPercent >= 70) return 'Good sleep';
    if (sleepQualityPercent >= 50) return 'Okay sleep';
    if (sleepQualityPercent > 0) return 'Poor sleep';
    return 'No data yet';
  }

  String get qualityArrow {
    if (sleepQualityPercent >= 70) return '↑';
    if (sleepQualityPercent >= 50) return '→';
    if (sleepQualityPercent > 0) return '↓';
    return '';
  }

  Color get qualityColor {
    if (sleepQualityPercent >= 70) return const Color(0xFF4cd964);
    if (sleepQualityPercent >= 50) return const Color(0xFFf5a623);
    if (sleepQualityPercent > 0) return const Color(0xFFff4757);
    return const Color(0xFF8e94b0);
  }

  String get moodBadge {
    if (sleepQualityPercent >= 85) return 'Well-rested';
    if (sleepQualityPercent >= 65) return 'Rested';
    if (sleepQualityPercent >= 45) return 'Tired';
    if (sleepQualityPercent > 0) return 'Exhausted';
    return 'Unknown';
  }

  Color get moodBadgeColor {
    if (sleepQualityPercent >= 85) return const Color(0xFF4cd964);
    if (sleepQualityPercent >= 65) return const Color(0xFF74b9ff);
    if (sleepQualityPercent >= 45) return const Color(0xFFf5a623);
    if (sleepQualityPercent > 0) return const Color(0xFFff4757);
    return const Color(0xFF8e94b0);
  }

  String get equippedHatEmoji {
    final e = hats.where((h) => h.equipped).firstOrNull;
    return e?.emoji ?? '';
  }

  String get equippedOutfitEmoji {
    final e = outfits.where((o) => o.equipped).firstOrNull;
    return e?.emoji ?? '';
  }

  String get equippedAccessoryEmoji {
    final e = accessories.where((a) => a.equipped).firstOrNull;
    return e?.emoji ?? '';
  }

  String get selectedThemeName {
    final t = roomThemes.where((t) => t['selected'] == true).firstOrNull;
    return (t?['name'] as String?) ?? 'Night Sky';
  }

  String get lockDurationText {
    final startMin = lockStartHour * 60 + lockStartMinute;
    final endMin = lockEndHour * 60 + lockEndMinute;
    final diff = endMin > startMin ? endMin - startMin : (1440 - startMin) + endMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (m == 0) return '$h hours';
    return '$h.${(m * 10 ~/ 60)} hours';
  }

  // ─── Load all data from Supabase ───────────────────────

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadProfile(),
        _loadSleepTasks(),
        _loadWeeklyData(),
        _loadAppLock(),
        _loadInventory(),
        _loadInsight(),
      ]);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      _loadDefaults();
    }

    isLoading = false;
    notifyListeners();
  }

  void _loadDefaults() {
    userName = 'User';
    tokens = 0;
    streak = 0;
    nappuLevel = 1;
    nappuXp = 0;
    sleepTasks = [
      {'task': 'No screen 30 mins before bed', 'coins': 20, 'done': false},
      {'task': 'Dim lights at 10:30 PM', 'coins': 15, 'done': false},
      {'task': '5-min mindfulness breathing', 'coins': 25, 'done': false},
      {'task': 'Sleep by 11:00 PM', 'coins': 30, 'done': false},
    ];
    weeklyData = [
      {'day': 'M', 'hours': 0.0, 'ideal': false},
      {'day': 'T', 'hours': 0.0, 'ideal': false},
      {'day': 'W', 'hours': 0.0, 'ideal': false},
      {'day': 'T', 'hours': 0.0, 'ideal': false},
      {'day': 'F', 'hours': 0.0, 'ideal': false},
      {'day': 'S', 'hours': 0.0, 'ideal': false},
      {'day': 'S', 'hours': 0.0, 'ideal': false},
    ];
    lockedApps = [
      LockedApp(name: 'Instagram', packageName: 'com.instagram.android', icon: Icons.camera_alt, iconColor: const Color(0xFFe1306c), status: 'Locked'),
      LockedApp(name: 'TikTok', packageName: 'com.zhiliaoapp.musically', icon: Icons.music_note, iconColor: const Color(0xFF69c9d0), status: 'Locked'),
      LockedApp(name: 'WhatsApp', packageName: 'com.whatsapp', icon: Icons.chat_bubble, iconColor: const Color(0xFF25d366), status: 'Reminder'),
      LockedApp(name: 'YouTube', packageName: 'com.google.android.youtube', icon: Icons.play_arrow, iconColor: const Color(0xFFff0000), status: 'Locked'),
    ];
    _loadDefaultShopItems();
    biweeklyInsight = '';
  }

  void _loadDefaultShopItems() {
    assert(_itemEmojis.keys.every(_itemPrices.containsKey));
    hats = [
      ShopItem(name: 'Top Hat', emoji: '🎩', price: 0, owned: true, equipped: true),
      ShopItem(name: 'Cap', emoji: '🧢', price: 0, owned: true),
      ShopItem(name: 'Crown', emoji: '👑', price: 120),
      ShopItem(name: 'Flower', emoji: '🌸', price: 80),
      ShopItem(name: 'Helmet', emoji: '🪖', price: 90),
      ShopItem(name: 'Grad Cap', emoji: '🎓', price: 100),
      ShopItem(name: 'Bear Ear', emoji: '🧸', price: 60),
      ShopItem(name: 'Halo', emoji: '✨', price: 200),
    ];
    outfits = [
      ShopItem(name: 'Pajamas', emoji: '👕', price: 0, owned: true, equipped: true),
      ShopItem(name: 'Sweater', emoji: '🧥', price: 100),
      ShopItem(name: 'Cape', emoji: '🦸', price: 150),
      ShopItem(name: 'Scarf', emoji: '🧣', price: 70),
    ];
    accessories = [
      ShopItem(name: 'Pillow', emoji: '🛏️', price: 50),
      ShopItem(name: 'Blanket', emoji: '🛋️', price: 80),
      ShopItem(name: 'Teddy', emoji: '🧸', price: 60),
      ShopItem(name: 'Moon Lamp', emoji: '🌙', price: 120),
    ];
    roomThemes = [
      {'name': 'Night Sky', 'emoji': '🌙', 'price': 0, 'owned': true, 'selected': true},
      {'name': 'Sakura', 'emoji': '🌸', 'price': 0, 'owned': true, 'selected': false},
      {'name': 'Mountain', 'emoji': '⛰️', 'price': 150, 'owned': false, 'selected': false},
    ];
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getProfile();
    if (profile != null) {
      userName = profile['display_name'] ?? 'User';
      tokens = profile['tokens'] ?? 0;
      streak = profile['streak'] ?? 0;
      nappuLevel = profile['nappu_level'] ?? 1;
      nappuXp = profile['nappu_xp'] ?? 0;
      nappuMaxXp = profile['nappu_max_xp'] ?? 1000;
      nappuMood = profile['nappu_mood'] ?? 'happy';
    }

    final lastLog = await SupabaseService.getLastSleepLog();
    if (lastLog != null) {
      lastNightSleep = (lastLog['duration_hours'] as num).toDouble();
      final q = lastLog['quality'] as String;
      sleepQualityPercent = q == 'Great' ? 95 : q == 'Good' ? 84 : q == 'Okay' ? 60 : 40;

      // Check if already logged today — compare against UTC date
      // because the server RPC uses current_date which is UTC
      final logDate = lastLog['log_date'] as String;
      final now = DateTime.now().toUtc();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      hasLoggedToday = logDate.startsWith(todayStr);
      isFirstLaunch = false;
    } else {
      hasLoggedToday = false;
      isFirstLaunch = true;
    }
  }

  Future<void> _loadSleepTasks() async {
    final tasks = await SupabaseService.getTodaysTasks();
    sleepTasks = tasks.map((t) => {
      'id': t['id'],
      'task': t['task_name'] as String,
      'coins': t['coins'] as int,
      'done': t['completed'] as bool,
    }).toList();
  }

  Future<void> _loadWeeklyData() async {
    final logs = await SupabaseService.getWeeklySleepLogs();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    weeklyData = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayIdx = (date.weekday - 1) % 7;
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final log = logs.where((l) => l['log_date'] == dateStr).firstOrNull;
      final hours = log != null ? (log['duration_hours'] as num).toDouble() : 0.0;
      return {
        'day': dayLabels[dayIdx],
        'hours': hours,
        'ideal': hours >= 7 && hours <= 9,
      };
    });
  }

  Future<void> _loadAppLock() async {
    final settings = await SupabaseService.getAppLockSettings();
    if (settings != null) {
      lockEnabled = settings['enabled'] ?? true;
      lockStartHour = settings['lock_start_hour'] ?? 22;
      lockStartMinute = settings['lock_start_minute'] ?? 30;
      lockEndHour = settings['lock_end_hour'] ?? 7;
      lockEndMinute = settings['lock_end_minute'] ?? 0;
    }

    final apps = await SupabaseService.getLockedApps();
    lockedApps = apps.map((a) {
      final name = a['app_name'] as String;
      return LockedApp(
        name: name,
        packageName: _appPackages[name] ?? '',
        icon: appIconCatalog[name] ?? Icons.apps,
        iconColor: appColorCatalog[name] ?? Colors.grey,
        status: a['status'] as String,
      );
    }).toList();

    // Sync native service if Android
    _syncNativeLock();
  }

  List<String> get _lockedPackageNames =>
      lockedApps.where((a) => a.status == 'Locked').map((a) => a.packageName).where((p) => p.isNotEmpty).toList();

  Future<void> _syncNativeLock() async {
    if (!AppLockNative.isAndroid) return;
    if (lockEnabled && _lockedPackageNames.isNotEmpty) {
      final running = await AppLockNative.isAppLockRunning();
      if (running) {
        await AppLockNative.updateAppLockConfig(
          _lockedPackageNames,
          startHour: lockStartHour,
          startMinute: lockStartMinute,
          endHour: lockEndHour,
          endMinute: lockEndMinute,
        );
      } else {
        await AppLockNative.startAppLock(
          _lockedPackageNames,
          startHour: lockStartHour,
          startMinute: lockStartMinute,
          endHour: lockEndHour,
          endMinute: lockEndMinute,
        );
      }
    } else {
      final running = await AppLockNative.isAppLockRunning();
      if (running) await AppLockNative.stopAppLock();
    }
  }

  Future<void> _loadInventory() async {
    _loadDefaultShopItems();

    for (final category in ['Hats', 'Outfits', 'Accessories', 'Themes']) {
      final items = await SupabaseService.getInventory(category);
      for (final item in items) {
        final name = item['item_name'] as String;
        final owned = item['owned'] as bool;
        final equipped = item['equipped'] as bool;

        if (category == 'Themes') {
          final idx = roomThemes.indexWhere((t) => t['name'] == name);
          if (idx != -1) {
            roomThemes[idx]['owned'] = owned;
            roomThemes[idx]['selected'] = equipped;
          }
        } else {
          final list = category == 'Hats' ? hats : category == 'Outfits' ? outfits : accessories;
          final idx = list.indexWhere((i) => i.name == name);
          if (idx != -1) {
            list[idx] = list[idx].copyWith(owned: owned, equipped: equipped);
          }
        }
      }
    }
  }

  Future<void> _loadInsight() async {
    final insight = await SupabaseService.getLatestInsight();
    if (insight != null) {
      biweeklyInsight = insight['insight_text'] ?? '';
    } else {
      // Auto-generate if we have enough data (7+ days of logs)
      final logged = weeklyData.where((d) => (d['hours'] as double) > 0).length;
      if (logged >= 7) {
        try {
          final res = await SupabaseService.generateBiweeklyInsight();
          if (res['success'] == true) {
            biweeklyInsight = res['insight_text'] as String;
            return;
          }
        } catch (_) {}
      }
      biweeklyInsight =
          'Log your sleep for two weeks to receive personalised biweekly insights. 🌙';
    }
  }

  // ─── Actions (optimistic UI + server-side RPC for sensitive ops) ─

  Future<void> toggleTask(int index) async {
    final task = sleepTasks[index];
    final newDone = !(task['done'] as bool);
    final coins = task['coins'] as int;

    // Optimistic UI update
    sleepTasks[index]['done'] = newDone;
    tokens += newDone ? coins : -coins;
    notifyListeners();

    // Server-side RPC handles tokens atomically
    final taskId = task['id'];
    if (taskId != null) {
      final res = await SupabaseService.toggleTask(taskId as int, newDone);
      if (res['success'] == true) {
        tokens = res['new_balance'] as int;
        notifyListeners();
      } else {
        // Revert on failure
        sleepTasks[index]['done'] = !newDone;
        tokens += newDone ? -coins : coins;
        notifyListeners();
      }
    }
  }

  void setSleepQuality(String quality) {
    currentSleepQuality = quality;
    notifyListeners();
  }

  Future<Map<String, dynamic>> logSleep() async {
    final duration = sleepDuration;
    final oldLastNightSleep = lastNightSleep;
    final oldHasLoggedToday = hasLoggedToday;
    final oldSleepQualityPercent = sleepQualityPercent;
    final oldNappuMood = nappuMood;
    final oldTokens = tokens;
    final oldStreak = streak;
    final oldNappuXp = nappuXp;
    final oldNappuLevel = nappuLevel;

    lastNightSleep = duration;
    hasLoggedToday = true;
    final q = currentSleepQuality;
    sleepQualityPercent = q == 'Great' ? 95 : q == 'Good' ? 84 : q == 'Okay' ? 60 : 40;
    nappuMood = _moodFromQuality(q);
    notifyListeners();

    try {
      final res = await SupabaseService.logSleep(
        quality: currentSleepQuality,
        bedtimeHour: currentBedtime.hour,
        bedtimeMinute: currentBedtime.minute,
        wakeupHour: currentWakeup.hour,
        wakeupMinute: currentWakeup.minute,
        durationHours: duration,
      );

      if (res['success'] == true) {
        tokens = res['tokens'] as int;
        streak = res['streak'] as int;
        nappuXp = res['nappu_xp'] as int;
        nappuLevel = res['nappu_level'] as int;
        await SupabaseService.updateNappuMood(nappuMood);
        await _loadWeeklyData();
        notifyListeners();
        return res;
      }
      throw Exception(res['error'] ?? 'Unable to log sleep');
    } catch (e) {
      lastNightSleep = oldLastNightSleep;
      hasLoggedToday = oldHasLoggedToday;
      sleepQualityPercent = oldSleepQualityPercent;
      nappuMood = oldNappuMood;
      tokens = oldTokens;
      streak = oldStreak;
      nappuXp = oldNappuXp;
      nappuLevel = oldNappuLevel;
      errorMessage = e.toString();
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  static String _moodFromQuality(String quality) {
    switch (quality) {
      case 'Great': return 'energized';
      case 'Good': return 'happy';
      case 'Okay': return 'tired';
      case 'Poor': return 'sleepy';
      default: return 'happy';
    }
  }

  Future<void> toggleLock() async {
    final oldEnabled = lockEnabled;
    lockEnabled = !lockEnabled;
    errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.updateAppLockSettings({'enabled': lockEnabled});
      await _syncNativeLock();
    } catch (e) {
      lockEnabled = oldEnabled;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateLockSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    final oldStartHour = lockStartHour;
    final oldStartMinute = lockStartMinute;
    final oldEndHour = lockEndHour;
    final oldEndMinute = lockEndMinute;
    lockStartHour = startHour;
    lockStartMinute = startMinute;
    lockEndHour = endHour;
    lockEndMinute = endMinute;
    errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.updateAppLockSettings({
        'lock_start_hour': startHour,
        'lock_start_minute': startMinute,
        'lock_end_hour': endHour,
        'lock_end_minute': endMinute,
      });
      await _syncNativeLock();
    } catch (e) {
      lockStartHour = oldStartHour;
      lockStartMinute = oldStartMinute;
      lockEndHour = oldEndHour;
      lockEndMinute = oldEndMinute;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<String> get availableAppsToAdd {
    final currentNames = lockedApps.map((a) => a.name).toSet();
    return appIconCatalog.keys.where((n) => !currentNames.contains(n)).toList();
  }

  Future<void> addLockedApp(String name) async {
    final app = LockedApp(
      name: name,
      packageName: _appPackages[name] ?? '',
      icon: appIconCatalog[name] ?? Icons.apps,
      iconColor: appColorCatalog[name] ?? Colors.grey,
      status: 'Locked',
    );
    lockedApps.add(app);
    errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.addLockedApp(name);
      await _syncNativeLock();
    } catch (e) {
      lockedApps.remove(app);
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeLockedApp(int index) async {
    final app = lockedApps.removeAt(index);
    errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.removeLockedApp(app.name);
      await _syncNativeLock();
    } catch (e) {
      lockedApps.insert(index, app);
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLockedAppStatus(int index) async {
    final app = lockedApps[index];
    final oldStatus = app.status;
    final newStatus = oldStatus == 'Locked' ? 'Reminder' : 'Locked';
    app.status = newStatus;
    errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.updateLockedAppStatus(app.name, newStatus);
      await _syncNativeLock();
    } catch (e) {
      app.status = oldStatus;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> emergencyOverride() async {
    const cost = 50;
    if (tokens < cost) return false;

    final oldTokens = tokens;
    tokens -= cost;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await SupabaseService.spendEmergencyOverrideTokens(cost: cost);
      if (res['success'] == true) {
        tokens = res['new_balance'] as int;
        notifyListeners();
        await AppLockNative.emergencyOverride(durationMs: 15 * 60 * 1000);
        return true;
      }
      tokens = oldTokens;
      notifyListeners();
      return false;
    } catch (e) {
      tokens = oldTokens;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateDisplayName(String name) async {
    userName = name;
    notifyListeners();
    await SupabaseService.updateProfile({'display_name': name});
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> purchaseItem(ShopItem item, String category) async {
    if (tokens < item.price) return;

    // Optimistic UI
    final oldTokens = tokens;
    tokens -= item.price;
    List<ShopItem> list;
    switch (category) {
      case 'Hats': list = hats; break;
      case 'Outfits': list = outfits; break;
      default: list = accessories;
    }
    final idx = list.indexOf(item);
    if (idx != -1) {
      list[idx] = item.copyWith(owned: true);
    }
    notifyListeners();

    // Server-side RPC checks balance + deducts atomically
    final res = await SupabaseService.purchaseItem(category, item.name, item.price);
    if (res['success'] == true) {
      tokens = res['new_balance'] as int;
      notifyListeners();
    } else {
      // Revert on failure
      tokens = oldTokens;
      if (idx != -1) {
        list[idx] = item.copyWith(owned: false);
      }
      notifyListeners();
    }
  }

  Future<void> equipItem(ShopItem item, String category) async {
    List<ShopItem> list;
    switch (category) {
      case 'Hats': list = hats; break;
      case 'Outfits': list = outfits; break;
      default: list = accessories;
    }
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(equipped: list[i] == item);
    }
    notifyListeners();

    // Equip is low-risk, direct write is fine
    await SupabaseService.equipItem(category, item.name);
  }

  Future<void> selectRoomTheme(String themeName) async {
    final theme = roomThemes.firstWhere((t) => t['name'] == themeName, orElse: () => {});
    if (theme.isEmpty) return;
    // Only select if owned
    if (theme['owned'] != true) return;
    for (var t in roomThemes) {
      t['selected'] = t['name'] == themeName;
    }
    notifyListeners();
    // Persist to DB (equipItem auto-unequips others in the category)
    await SupabaseService.equipItem('Themes', themeName);
  }

  Future<void> purchaseRoomTheme(String themeName) async {
    final theme = roomThemes.firstWhere((t) => t['name'] == themeName, orElse: () => {});
    if (theme.isEmpty || theme['owned'] == true) return;
    final price = theme['price'] as int;
    if (tokens < price) return;

    // Optimistic UI
    final oldTokens = tokens;
    tokens -= price;
    theme['owned'] = true;
    theme['selected'] = true;
    for (var t in roomThemes) {
      if (t['name'] != themeName) t['selected'] = false;
    }
    notifyListeners();

    final res = await SupabaseService.purchaseItem('Themes', themeName, price);
    if (res['success'] == true) {
      tokens = res['new_balance'] as int;
      notifyListeners();
    } else {
      // Revert
      tokens = oldTokens;
      theme['owned'] = false;
      theme['selected'] = false;
      notifyListeners();
    }
  }

  double get sleepDuration {
    final bedMin = currentBedtime.hour * 60 + currentBedtime.minute;
    final wakeMin = currentWakeup.hour * 60 + currentWakeup.minute;
    final diff = wakeMin > bedMin ? wakeMin - bedMin : (1440 - bedMin) + wakeMin;
    return diff / 60.0;
  }

  String get sleepDurationFormatted {
    final d = sleepDuration;
    final h = d.floor();
    final m = ((d - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  void setBedtime(TimeOfDay time) {
    currentBedtime = time;
    notifyListeners();
  }

  void setWakeup(TimeOfDay time) {
    currentWakeup = time;
    notifyListeners();
  }
}
