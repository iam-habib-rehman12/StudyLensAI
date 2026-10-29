import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 8, 25, 12);

  test('formats recent timestamps', () {
    expect(
      relativeTime(now.subtract(const Duration(seconds: 30)), now: now),
      'Just now',
    );
    expect(
      relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(hours: 3)), now: now),
      '3h ago',
    );
  });

  test('formats day-based and older timestamps', () {
    expect(
      relativeTime(now.subtract(const Duration(days: 1)), now: now),
      'Yesterday',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 3)), now: now),
      '3d ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 10)), now: now),
      '15 Aug 2026',
    );
  });

  test('treats future timestamps as just now', () {
    expect(
      relativeTime(now.add(const Duration(minutes: 1)), now: now),
      'Just now',
    );
  });
}
