import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});

  @override
  State<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  bool _isSaving = false;

  Future<void> _pickBedtime(AppState state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: state.currentBedtime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) state.setBedtime(picked);
  }

  Future<void> _pickWakeup(AppState state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: state.currentWakeup,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) state.setWakeup(picked);
  }

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
                children: [
                  const Text('🌕', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  const Text(
                    'Sleep Log',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Record your sleep duration!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildQualitySelector(state),
                  const SizedBox(height: 16),
                  _buildDurationPicker(state),
                  const SizedBox(height: 16),
                  _buildLogButton(state),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(state),
                  const SizedBox(height: 20),
                  _buildBiweeklyInsight(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildQualitySelector(AppState state) {
    final qualities = [
      {'label': 'Poor', 'image': 'assets/images/sleep/poor.png'},
      {'label': 'Okay', 'image': 'assets/images/sleep/okay.png'},
      {'label': 'Good', 'image': 'assets/images/sleep/good.png'},
      {'label': 'Great', 'image': 'assets/images/sleep/great.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How did you sleep?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: qualities.map((q) {
            final selected = state.currentSleepQuality == q['label'];
            return Expanded(
              child: GestureDetector(
                onTap: () => state.setSleepQuality(q['label']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surfaceLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          q['image']!,
                          width: selected ? 50 : 44,
                          height: selected ? 50 : 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selected ? '${q['label']} \u2713' : q['label']!,
                        style: TextStyle(
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationPicker(AppState state) {
    final bedHour = state.currentBedtime.hourOfPeriod == 0 ? 12 : state.currentBedtime.hourOfPeriod;
    final bedPeriod = state.currentBedtime.period == DayPeriod.am ? 'AM' : 'PM';
    final wakeHour = state.currentWakeup.hourOfPeriod == 0 ? 12 : state.currentWakeup.hourOfPeriod;
    final wakePeriod = state.currentWakeup.period == DayPeriod.am ? 'AM' : 'PM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SLEEP DURATION',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickBedtime(state),
                  child: Column(
                    children: [
                      Text(
                        '$bedHour'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bedtime $bedPeriod',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 20,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickWakeup(state),
                  child: Column(
                    children: [
                      Text(
                        '$wakeHour'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Wakeup $wakePeriod',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    state.sleepDurationFormatted,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogButton(AppState state) {
    final logged = state.hasLoggedToday;

    if (logged && !_isSaving) {
      // ── Already logged today: show success state + subtle update option ──
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.4), width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sleep Logged Today',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              setState(() => _isSaving = true);
              final messenger = ScaffoldMessenger.of(context);
              final res = await state.logSleep();
              if (mounted) {
                final success = res['success'] == true;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Sleep log updated' : '⚠️ Could not update'),
                    backgroundColor: success ? AppColors.green : AppColors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              if (mounted) setState(() => _isSaving = false);
            },
            child: const Text(
              'Tap to update sleep log',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    // ── Not logged yet (or currently saving): show primary action button ──
    return GestureDetector(
      onTap: _isSaving ? null : () async {
        setState(() => _isSaving = true);
        final messenger = ScaffoldMessenger.of(context);
        final res = await state.logSleep();
        if (mounted) {
          final success = res['success'] == true;
          final firstLog = res['first_log_today'] == true;
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(success ? '🎉 ' : '⚠️ ', style: const TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      success
                          ? firstLog
                              ? 'Sleep logged! +50 tokens earned'
                              : 'Sleep log updated'
                          : 'Could not save sleep log',
                    ),
                  ),
                ],
              ),
              backgroundColor: success ? AppColors.green : AppColors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (mounted) setState(() => _isSaving = false);
      },
      child: Opacity(
        opacity: _isSaving ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
                const Text(
                  'Log Sleep · Earn 30 ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('🪙', style: TextStyle(fontSize: 18)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < state.weeklyData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            state.weeklyData[idx]['day'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: state.weeklyData.asMap().entries.map((entry) {
                final data = entry.value;
                final hours = data['hours'] as double;
                final ideal = data['ideal'] as bool;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: hours,
                      color: ideal ? AppColors.sleepGood : AppColors.sleepOther,
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.sleepGood, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            const Text('7-9h ideal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(width: 16),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.sleepOther, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            const Text('other', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildBiweeklyInsight(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BIWEEKLY INSIGHT',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.biweeklyInsight.isNotEmpty
                ? state.biweeklyInsight
                : 'Log sleep for 7+ days to get your first personalized insight! 🌙',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
