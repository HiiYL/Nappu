import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;

  // ─── Auth ───────────────────────────────────────────────

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static bool get isAuthenticated => currentUser != null;

  // ─── Profile ────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    final res = await client
        .from('profiles')
        .select()
        .eq('id', userId!)
        .maybeSingle();
    return res;
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (userId == null) return;
    data['updated_at'] = DateTime.now().toIso8601String();
    await client.from('profiles').update(data).eq('id', userId!);
  }

  static Future<void> addTokens(int amount, String reason) async {
    if (userId == null) return;
    // Update balance
    final profile = await getProfile();
    if (profile == null) return;
    final newBalance = (profile['tokens'] as int) + amount;
    await updateProfile({'tokens': newBalance});
    // Log transaction
    await client.from('token_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'reason': reason,
    });
  }

  static Future<void> updateStreak(int streak) async {
    await updateProfile({'streak': streak});
  }

  static Future<void> updateNappuStats({
    int? level,
    int? xp,
    String? mood,
  }) async {
    final data = <String, dynamic>{};
    if (level != null) data['nappu_level'] = level;
    if (xp != null) data['nappu_xp'] = xp;
    if (mood != null) data['nappu_mood'] = mood;
    if (data.isNotEmpty) await updateProfile(data);
  }

  // ─── Sleep Logs ─────────────────────────────────────────

  static Future<void> logSleep({
    required String quality,
    required int bedtimeHour,
    required int wakeupHour,
    required double durationHours,
    int tokensEarned = 50,
  }) async {
    if (userId == null) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await client.from('sleep_logs').upsert({
      'user_id': userId,
      'log_date': dateStr,
      'quality': quality,
      'bedtime_hour': bedtimeHour,
      'wakeup_hour': wakeupHour,
      'duration_hours': durationHours,
      'tokens_earned': tokensEarned,
    }, onConflict: 'user_id,log_date');

    await addTokens(tokensEarned, 'Sleep log');
  }

  static Future<List<Map<String, dynamic>>> getWeeklySleepLogs() async {
    if (userId == null) return [];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final fromStr =
        '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

    final res = await client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId!)
        .gte('log_date', fromStr)
        .order('log_date');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>?> getLastSleepLog() async {
    if (userId == null) return null;
    final res = await client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId!)
        .order('log_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  // ─── Sleep Tasks ────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTodaysTasks() async {
    if (userId == null) return [];
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final res = await client
        .from('sleep_tasks')
        .select()
        .eq('user_id', userId!)
        .eq('task_date', dateStr)
        .order('id');

    final tasks = List<Map<String, dynamic>>.from(res);

    // If no tasks for today, seed them
    if (tasks.isEmpty) {
      await _seedTodaysTasks(dateStr);
      return getTodaysTasks();
    }
    return tasks;
  }

  static Future<void> _seedTodaysTasks(String dateStr) async {
    if (userId == null) return;
    final defaults = [
      {'task_name': 'No screen 30 mins before bed', 'coins': 20},
      {'task_name': 'Dim lights at 10:30 PM', 'coins': 15},
      {'task_name': '5-min mindfulness breathing', 'coins': 25},
      {'task_name': 'Sleep by 11:00 PM', 'coins': 30},
    ];
    for (final t in defaults) {
      await client.from('sleep_tasks').insert({
        'user_id': userId,
        'task_date': dateStr,
        'task_name': t['task_name'],
        'coins': t['coins'],
      });
    }
  }

  static Future<void> toggleTask(int taskId, bool completed) async {
    await client
        .from('sleep_tasks')
        .update({'completed': completed}).eq('id', taskId);
  }

  // ─── App Lock ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> getAppLockSettings() async {
    if (userId == null) return null;
    final res = await client
        .from('app_lock_settings')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();
    return res;
  }

  static Future<void> updateAppLockSettings(Map<String, dynamic> data) async {
    if (userId == null) return;
    data['updated_at'] = DateTime.now().toIso8601String();
    await client
        .from('app_lock_settings')
        .update(data)
        .eq('user_id', userId!);
  }

  static Future<List<Map<String, dynamic>>> getLockedApps() async {
    if (userId == null) return [];
    final res = await client
        .from('locked_apps')
        .select()
        .eq('user_id', userId!)
        .order('id');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> updateLockedAppStatus(
      String appName, String status) async {
    if (userId == null) return;
    await client
        .from('locked_apps')
        .update({'status': status})
        .eq('user_id', userId!)
        .eq('app_name', appName);
  }

  // ─── Inventory ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getInventory(
      String category) async {
    if (userId == null) return [];
    final res = await client
        .from('inventory')
        .select()
        .eq('user_id', userId!)
        .eq('category', category)
        .order('id');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> purchaseItem(String category, String itemName) async {
    if (userId == null) return;
    await client
        .from('inventory')
        .upsert({
          'user_id': userId,
          'category': category,
          'item_name': itemName,
          'owned': true,
        }, onConflict: 'user_id,category,item_name');
  }

  static Future<void> equipItem(String category, String itemName) async {
    if (userId == null) return;
    // Unequip all in category
    await client
        .from('inventory')
        .update({'equipped': false})
        .eq('user_id', userId!)
        .eq('category', category);
    // Equip selected
    await client
        .from('inventory')
        .update({'equipped': true})
        .eq('user_id', userId!)
        .eq('category', category)
        .eq('item_name', itemName);
  }

  // ─── Biweekly Insights ─────────────────────────────────

  static Future<Map<String, dynamic>?> getLatestInsight() async {
    if (userId == null) return null;
    final res = await client
        .from('biweekly_insights')
        .select()
        .eq('user_id', userId!)
        .order('period_end', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  static Future<void> generateBiweeklyInsight() async {
    if (userId == null) return;
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final fromStr =
        '${twoWeeksAgo.year}-${twoWeeksAgo.month.toString().padLeft(2, '0')}-${twoWeeksAgo.day.toString().padLeft(2, '0')}';
    final toStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final logs = await client
        .from('sleep_logs')
        .select('duration_hours')
        .eq('user_id', userId!)
        .gte('log_date', fromStr)
        .lte('log_date', toStr);

    if (logs.isEmpty) return;

    final durations =
        logs.map((l) => (l['duration_hours'] as num).toDouble()).toList();
    final avg = durations.reduce((a, b) => a + b) / durations.length;

    String insightText;
    if (avg >= 7 && avg <= 9) {
      insightText =
          'Your average sleep is ${avg.toStringAsFixed(1)} hrs — within the ideal range. Keep it up! 🌟';
    } else if (avg < 7) {
      insightText =
          'Your average sleep is ${avg.toStringAsFixed(1)} hrs — slightly below ideal. Try sleeping 20 min earlier on weekdays. 🌙';
    } else {
      insightText =
          'Your average sleep is ${avg.toStringAsFixed(1)} hrs — above average. Make sure you\'re not oversleeping. ☀️';
    }

    await client.from('biweekly_insights').insert({
      'user_id': userId,
      'period_start': fromStr,
      'period_end': toStr,
      'avg_sleep_hours': avg,
      'insight_text': insightText,
    });
  }
}
