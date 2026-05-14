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

  // Token/streak/level mutations are handled by RPC functions server-side.
  // These safe update methods are kept for display_name, nappu_mood, etc.

  static Future<void> updateNappuMood(String mood) async {
    await updateProfile({'nappu_mood': mood});
  }

  // ─── Sleep Logs ─────────────────────────────────────────

  /// Logs sleep via server-side RPC. Awards tokens, updates streak/XP atomically.
  /// Returns {success, first_log_today, tokens, streak, nappu_xp, nappu_level}.
  static Future<Map<String, dynamic>> logSleep({
    required String quality,
    required int bedtimeHour,
    required int bedtimeMinute,
    required int wakeupHour,
    required int wakeupMinute,
    required double durationHours,
    int tokensEarned = 50,
  }) async {
    if (userId == null) return {'success': false};
    final res = await client.rpc('log_sleep', params: {
      'p_quality': quality,
      'p_bedtime_hour': bedtimeHour,
      'p_bedtime_minute': bedtimeMinute,
      'p_wakeup_hour': wakeupHour,
      'p_wakeup_minute': wakeupMinute,
      'p_duration_hours': durationHours,
      'p_tokens_earned': tokensEarned,
    });
    return Map<String, dynamic>.from(res as Map);
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

  /// Complete/uncomplete a task via server-side RPC.
  /// Returns {success, tokens_awarded/deducted, new_balance} or {success: false, error}.
  static Future<Map<String, dynamic>> toggleTask(int taskId, bool completed) async {
    final fn = completed ? 'complete_daily_task' : 'uncomplete_daily_task';
    final res = await client.rpc(fn, params: {'p_task_id': taskId});
    return Map<String, dynamic>.from(res as Map);
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

  static Future<void> addLockedApp(String appName) async {
    if (userId == null) return;
    await client.from('locked_apps').upsert({
      'user_id': userId,
      'app_name': appName,
      'status': 'Locked',
    });
  }

  static Future<void> removeLockedApp(String appName) async {
    if (userId == null) return;
    await client
        .from('locked_apps')
        .delete()
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

  /// Purchase item via server-side RPC. Checks balance, deducts tokens atomically.
  /// Returns {success, new_balance} or {success: false, error}.
  static Future<Map<String, dynamic>> purchaseItem(
      String category, String itemName, int price) async {
    if (userId == null) return {'success': false};
    final res = await client.rpc('purchase_shop_item', params: {
      'p_category': category,
      'p_item_name': itemName,
      'p_price': price,
    });
    return Map<String, dynamic>.from(res as Map);
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

  // ─── Token Transactions ──────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTokenTransactions({int limit = 50}) async {
    if (userId == null) return [];
    final res = await client
        .from('token_transactions')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
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

  /// Generate biweekly insight via server-side RPC.
  /// Returns {success, avg_sleep_hours, insight_text, log_count} or {success: false, error}.
  static Future<Map<String, dynamic>> generateBiweeklyInsight() async {
    if (userId == null) return {'success': false};
    final res = await client.rpc('generate_biweekly_insight');
    return Map<String, dynamic>.from(res as Map);
  }
}
