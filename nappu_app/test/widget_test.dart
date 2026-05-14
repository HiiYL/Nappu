import 'package:flutter_test/flutter_test.dart';
import 'package:nappu_app/models/app_state.dart';

void main() {
  test('Sleep duration calculated correctly', () {
    final state = AppState();
    state.setBedtime(10);
    state.setWakeup(6);
    expect(state.sleepDuration, 8);
  });
}
