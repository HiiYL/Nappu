import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nappu_app/models/app_state.dart';

void main() {
  test('Sleep duration calculated correctly', () {
    final state = AppState();
    state.setBedtime(const TimeOfDay(hour: 22, minute: 0));
    state.setWakeup(const TimeOfDay(hour: 6, minute: 0));
    expect(state.sleepDuration, 8.0);
  });

  test('Sleep duration with minutes', () {
    final state = AppState();
    state.setBedtime(const TimeOfDay(hour: 22, minute: 30));
    state.setWakeup(const TimeOfDay(hour: 6, minute: 0));
    expect(state.sleepDuration, 7.5);
  });
}
