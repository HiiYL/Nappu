import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import 'token_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => state.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(state),
                  ],
                  if (SupabaseService.isAnonymous) ...[
                    const SizedBox(height: 12),
                    _buildGuestBanner(context),
                  ],
                  if (state.isFirstLaunch) ...[
                    const SizedBox(height: 16),
                    _buildWelcomeCard(state),
                  ],
                  const SizedBox(height: 16),
                  _buildStreakBanner(state),
                  const SizedBox(height: 16),
                  _buildNappuScene(state),
                  const SizedBox(height: 16),
                  _buildSleepStats(state),
                  const SizedBox(height: 20),
                  _buildSleepTasks(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(AppState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Failed to load data. Pull down to retry.',
              style: TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUpgradeDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Guest account — tap to save your progress',
                style: TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.accent, size: 14),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Save Your Progress',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add an email and password to keep your tokens, streak, and Nappu items.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Password (min 6 chars)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later', style: TextStyle(color: AppColors.textMuted)),
                ),
                TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    if (email.isEmpty || password.isEmpty) {
                      setDialogState(() => error = 'Please fill in both fields');
                      return;
                    }
                    if (password.length < 6) {
                      setDialogState(() => error = 'Password must be at least 6 characters');
                      return;
                    }
                    try {
                      await SupabaseService.client.auth.updateUser(
                        UserAttributes(email: email, password: password),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('🎉 Account saved! You can now sign in with email.'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => error = e.toString().replaceAll('AuthException: ', ''));
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2a2d5e), Color(0xFF1c2340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\ud83d\udc11', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Nappu!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your sleep companion is ready',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '\u2022 Complete sleep tasks to earn tokens\n\u2022 Log your sleep each morning\n\u2022 Use tokens to dress up Nappu\n\u2022 Set app locks to build better habits',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.greeting},',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      state.userName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🌙', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TokenHistoryScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.tokens}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSettingsSheet(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.settings, color: AppColors.textSecondary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakBanner(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const Text('\ud83d\udd25', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.streak}-Day Streak!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nappu is ${state.nappuMood} — keep it up!',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${state.streak}',
            style: const TextStyle(
              color: AppColors.streakOrange,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNappuScene(AppState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cx = w / 2; // center x
            return Stack(
              children: [
                // Sky
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0d1b3e), Color(0xFF162040)],
                      ),
                    ),
                  ),
                ),
                // Wooden floor
                Positioned(
                  left: 0, right: 0, bottom: 0, height: 85,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF5a3e28), Color(0xFF4a3220)],
                      ),
                    ),
                    child: CustomPaint(painter: _FloorBoardPainter()),
                  ),
                ),
                // Stars
                Positioned(top: 14, left: cx - 80, child: const Text('\u2b50', style: TextStyle(fontSize: 12))),
                Positioned(top: 8, left: cx + 60, child: const Text('\u2b50', style: TextStyle(fontSize: 10))),
                Positioned(top: 28, left: cx - 40, child: const Text('\u2728', style: TextStyle(fontSize: 10))),
                Positioned(top: 18, left: cx + 30, child: const Text('\u2728', style: TextStyle(fontSize: 8))),
                Positioned(top: 40, left: cx + 80, child: const Text('\u2b50', style: TextStyle(fontSize: 8))),
                // Moon
                Positioned(
                  top: 10, left: cx + 40,
                  child: const Text('\ud83c\udf19', style: TextStyle(fontSize: 30)),
                ),
                // Window (left wall)
                Positioned(
                  top: 30, left: cx - 120,
                  child: Container(
                    width: 44, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2550),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border.all(color: const Color(0xFF3e4a70), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\ud83c\udf19', style: TextStyle(fontSize: 14)),
                        Container(width: 30, height: 1, color: const Color(0xFF3e4a70)),
                        const Text('\u2b50', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                // Framed picture (right wall)
                Positioned(
                  top: 34, left: cx + 65,
                  child: Container(
                    width: 42, height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2550),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFF6a5a40), width: 2),
                    ),
                    child: const Center(
                      child: Text('\u26f0\ufe0f', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                // Floor lamp (right of center)
                Positioned(
                  bottom: 55, left: cx + 80,
                  child: Column(
                    children: [
                      Container(
                        width: 28, height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFe8c860),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(4)),
                        ),
                      ),
                      Container(width: 3, height: 40, color: const Color(0xFF8a7a60)),
                      Container(
                        width: 16, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFF8a7a60), borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),
                // Bed (centered, slightly left)
                Positioned(
                  bottom: 60, left: cx - 100,
                  child: SizedBox(
                    width: 120, height: 60,
                    child: Stack(
                      children: [
                        // Bed frame
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6a8a7a),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF5a7a6a), width: 1),
                            ),
                          ),
                        ),
                        // Headboard
                        Positioned(
                          bottom: 10, left: 0,
                          child: Container(
                            width: 14, height: 44,
                            decoration: BoxDecoration(color: const Color(0xFF7a5a3a), borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        // Footboard
                        Positioned(
                          bottom: 10, right: 0,
                          child: Container(
                            width: 10, height: 30,
                            decoration: BoxDecoration(color: const Color(0xFF7a5a3a), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                        // Pillow
                        Positioned(
                          bottom: 26, left: 18,
                          child: Container(
                            width: 30, height: 18,
                            decoration: BoxDecoration(color: const Color(0xFFe8e0d0), borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        // Blanket
                        Positioned(
                          bottom: 16, left: 30, right: 14,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(color: const Color(0xFF5a8a7a), borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nappu sheep (center-right, beside bed)
                Positioned(
                  bottom: 68, left: cx + 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text('\ud83d\udc11', style: TextStyle(fontSize: 52)),
                      // Zzz
                      const Positioned(
                        top: -14, right: -8,
                        child: Text('Zzz', style: TextStyle(
                          fontSize: 12, color: Color(0xFF8899cc),
                          fontWeight: FontWeight.bold, fontStyle: FontStyle.italic,
                        )),
                      ),
                      if (state.equippedHatEmoji.isNotEmpty)
                        Positioned(
                          top: -8, left: 8,
                          child: Text(state.equippedHatEmoji, style: const TextStyle(fontSize: 18)),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSleepStats(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  'LAST NIGHT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${state.lastNightSleep}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'hrs',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.sleepDeltaText.isNotEmpty ? state.sleepDeltaText : 'No data',
                  style: TextStyle(
                    color: state.sleepDeltaColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.cardBorder),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'QUALITY',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${state.sleepQualityPercent}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '%',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.qualityArrow} ${state.qualityLabel}',
                  style: TextStyle(
                    color: state.qualityColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.cardBorder),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'BEDTIME',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.bedtimeDisplay,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'On target',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: Provider.of<AppState>(context, listen: false).userName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Display Name', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final state = Provider.of<AppState>(context, listen: false);
              state.updateDisplayName(name);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.accent),
                title: const Text('Edit Display Name', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditNameDialog(context);
                },
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.red),
                title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dlg) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text(
                        'Are you sure you want to sign out?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dlg),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dlg);
                            await SupabaseService.signOut();
                          },
                          child: const Text('Sign Out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepTasks(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tonight's Tasks",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (state.sleepTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: const Column(
              children: [
                Text('😴', style: TextStyle(fontSize: 28)),
                SizedBox(height: 8),
                Text(
                  'No tasks yet — pull down to refresh',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ...state.sleepTasks.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          final done = task['done'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => state.toggleTask(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.green : Colors.transparent,
                        border: Border.all(
                          color: done ? AppColors.green : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task['task'] as String,
                        style: TextStyle(
                          color: done ? AppColors.textSecondary : AppColors.textPrimary,
                          fontSize: 14,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '+${task['coins']}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FloorBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4a3420)
      ..strokeWidth = 0.5;
    // Horizontal plank lines
    for (double y = 20; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Staggered vertical joints
    for (int row = 0; row < 4; row++) {
      final yTop = row * 22.0;
      final offset = row.isOdd ? size.width * 0.33 : 0.0;
      for (double x = offset; x < size.width; x += size.width * 0.33) {
        canvas.drawLine(Offset(x, yTop), Offset(x, yTop + 22), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
