import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nappu_app/models/app_state.dart';

void main() {
  // ─── Sleep duration ──────────────────────────────────────

  group('Sleep duration', () {
    test('8h overnight (22:00 → 06:00)', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 22, minute: 0));
      state.setWakeup(const TimeOfDay(hour: 6, minute: 0));
      expect(state.sleepDuration, 8.0);
    });

    test('7.5h with minutes (22:30 → 06:00)', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 22, minute: 30));
      state.setWakeup(const TimeOfDay(hour: 6, minute: 0));
      expect(state.sleepDuration, 7.5);
    });

    test('6.5h late bedtime (23:45 → 06:15)', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 23, minute: 45));
      state.setWakeup(const TimeOfDay(hour: 6, minute: 15));
      expect(state.sleepDuration, 6.5);
    });

    test('same-day duration (01:00 → 07:00)', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 1, minute: 0));
      state.setWakeup(const TimeOfDay(hour: 7, minute: 0));
      expect(state.sleepDuration, 6.0);
    });

    test('same time returns 24h (edge case)', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 8, minute: 0));
      state.setWakeup(const TimeOfDay(hour: 8, minute: 0));
      expect(state.sleepDuration, 24.0);
    });

    test('formatted string matches', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 22, minute: 30));
      state.setWakeup(const TimeOfDay(hour: 6, minute: 15));
      expect(state.sleepDurationFormatted, '7h 45m');
    });

    test('formatted string whole hours', () {
      final state = AppState();
      state.setBedtime(const TimeOfDay(hour: 22, minute: 0));
      state.setWakeup(const TimeOfDay(hour: 6, minute: 0));
      expect(state.sleepDurationFormatted, '8h');
    });
  });

  // ─── Lock duration text ────────────────────────────────

  group('Lock duration text', () {
    test('overnight 22:30 → 07:00 = 8.5 hours', () {
      final state = AppState();
      state.lockStartHour = 22;
      state.lockStartMinute = 30;
      state.lockEndHour = 7;
      state.lockEndMinute = 0;
      expect(state.lockDurationText, '8.5 hours');
    });

    test('exact hours 22:00 → 06:00 = 8 hours', () {
      final state = AppState();
      state.lockStartHour = 22;
      state.lockStartMinute = 0;
      state.lockEndHour = 6;
      state.lockEndMinute = 0;
      expect(state.lockDurationText, '8 hours');
    });
  });

  // ─── Computed quality/mood labels ────────────────────────

  group('Quality labels', () {
    test('Great sleep at 95%', () {
      final state = AppState();
      state.sleepQualityPercent = 95;
      expect(state.qualityLabel, 'Great sleep!');
      expect(state.qualityArrow, '↑');
    });

    test('Good sleep at 75%', () {
      final state = AppState();
      state.sleepQualityPercent = 75;
      expect(state.qualityLabel, 'Good sleep');
    });

    test('Okay sleep at 55%', () {
      final state = AppState();
      state.sleepQualityPercent = 55;
      expect(state.qualityLabel, 'Okay sleep');
      expect(state.qualityArrow, '→');
    });

    test('Poor sleep at 30%', () {
      final state = AppState();
      state.sleepQualityPercent = 30;
      expect(state.qualityLabel, 'Poor sleep');
      expect(state.qualityArrow, '↓');
    });

    test('No data at 0%', () {
      final state = AppState();
      state.sleepQualityPercent = 0;
      expect(state.qualityLabel, 'No data yet');
      expect(state.qualityArrow, '');
    });
  });

  group('Mood badges', () {
    test('Well-rested at 90%', () {
      final state = AppState();
      state.sleepQualityPercent = 90;
      expect(state.moodBadge, 'Well-rested');
    });

    test('Rested at 70%', () {
      final state = AppState();
      state.sleepQualityPercent = 70;
      expect(state.moodBadge, 'Rested');
    });

    test('Tired at 50%', () {
      final state = AppState();
      state.sleepQualityPercent = 50;
      expect(state.moodBadge, 'Tired');
    });

    test('Exhausted at 20%', () {
      final state = AppState();
      state.sleepQualityPercent = 20;
      expect(state.moodBadge, 'Exhausted');
    });

    test('Unknown at 0%', () {
      final state = AppState();
      state.sleepQualityPercent = 0;
      expect(state.moodBadge, 'Unknown');
    });
  });

  // ─── Weekly average ──────────────────────────────────────

  group('Weekly average sleep', () {
    test('calculates average of logged days only', () {
      final state = AppState();
      state.weeklyData = [
        {'day': 'M', 'hours': 7.0, 'ideal': true},
        {'day': 'T', 'hours': 8.0, 'ideal': true},
        {'day': 'W', 'hours': 0.0, 'ideal': false},
        {'day': 'T', 'hours': 9.0, 'ideal': true},
        {'day': 'F', 'hours': 0.0, 'ideal': false},
        {'day': 'S', 'hours': 0.0, 'ideal': false},
        {'day': 'S', 'hours': 0.0, 'ideal': false},
      ];
      expect(state.weeklyAvgSleep, 8.0);
    });

    test('returns 0 when no data', () {
      final state = AppState();
      state.weeklyData = [
        {'day': 'M', 'hours': 0.0, 'ideal': false},
        {'day': 'T', 'hours': 0.0, 'ideal': false},
      ];
      expect(state.weeklyAvgSleep, 0.0);
    });
  });

  // ─── Sleep delta text ────────────────────────────────────

  group('Sleep delta text', () {
    test('above average', () {
      final state = AppState();
      state.lastNightSleep = 8.5;
      state.weeklyData = [
        {'day': 'M', 'hours': 7.0, 'ideal': true},
        {'day': 'T', 'hours': 7.0, 'ideal': true},
      ];
      expect(state.sleepDeltaText, contains('+'));
    });

    test('below average', () {
      final state = AppState();
      state.lastNightSleep = 5.0;
      state.weeklyData = [
        {'day': 'M', 'hours': 8.0, 'ideal': true},
        {'day': 'T', 'hours': 8.0, 'ideal': true},
      ];
      expect(state.sleepDeltaText, contains('-'));
    });

    test('empty when no data', () {
      final state = AppState();
      state.lastNightSleep = 0;
      expect(state.sleepDeltaText, '');
    });
  });

  // ─── Equipped item emojis ────────────────────────────────

  group('Equipped emojis', () {
    test('returns emoji of equipped hat', () {
      final state = AppState();
      state.hats = [
        ShopItem(name: 'Crown', emoji: '👑', price: 120, owned: true, equipped: true),
        ShopItem(name: 'Cap', emoji: '🧢', price: 0, owned: true),
      ];
      expect(state.equippedHatEmoji, '👑');
    });

    test('returns empty when no hat equipped', () {
      final state = AppState();
      state.hats = [
        ShopItem(name: 'Cap', emoji: '🧢', price: 0, owned: true),
      ];
      expect(state.equippedHatEmoji, '');
    });
  });

  // ─── Greeting ────────────────────────────────────────────

  test('greeting is non-empty', () {
    final state = AppState();
    expect(state.greeting, isNotEmpty);
  });
}
