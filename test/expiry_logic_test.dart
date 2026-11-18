import 'package:expiryvault/utils/expiry_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daysRemaining', () {
    test('far-future expiry is positive', () {
      expect(
        daysRemaining(DateTime(2027, 1, 1), now: DateTime(2026, 11, 18)),
        44,
      );
    });

    test('expiry today is 0', () {
      expect(
        daysRemaining(DateTime(2026, 11, 18), now: DateTime(2026, 11, 18)),
        0,
      );
    });

    test('expiry tomorrow is 1', () {
      expect(
        daysRemaining(DateTime(2026, 11, 19), now: DateTime(2026, 11, 18)),
        1,
      );
    });

    test('already expired is negative', () {
      expect(
        daysRemaining(DateTime(2026, 11, 10), now: DateTime(2026, 11, 18)),
        -8,
      );
    });

    test('time of day is ignored', () {
      expect(
        daysRemaining(
          DateTime(2026, 11, 19, 23, 59),
          now: DateTime(2026, 11, 18, 0, 1),
        ),
        1,
      );
    });

    test('leap-year date: 2028-02-29 from 2028-02-28 is 1 day', () {
      expect(
        daysRemaining(DateTime(2028, 2, 29), now: DateTime(2028, 2, 28)),
        1,
      );
    });

    test('leap-year date: 2028-02-29 from 2027-02-28 is 366 days', () {
      expect(
        daysRemaining(DateTime(2028, 2, 29), now: DateTime(2027, 2, 28)),
        366,
      );
    });

    test('month boundary: 2026-12-01 from 2026-11-30 is 1 day', () {
      expect(
        daysRemaining(DateTime(2026, 12, 1), now: DateTime(2026, 11, 30)),
        1,
      );
    });
  });

  group('statusFor', () {
    final now = DateTime(2026, 11, 18);

    test('more than 30 days out is valid', () {
      expect(statusFor(DateTime(2026, 12, 19), now: now), ExpiryStatus.valid);
    });

    test('exactly 31 days out is valid', () {
      expect(statusFor(DateTime(2026, 12, 19), now: now), ExpiryStatus.valid);
    });

    test('exactly 30 days out is expiring soon', () {
      expect(
        statusFor(DateTime(2026, 12, 18), now: now),
        ExpiryStatus.expiringSoon,
      );
    });

    test('expiring today is expiring soon, not expired', () {
      expect(
        statusFor(DateTime(2026, 11, 18), now: now),
        ExpiryStatus.expiringSoon,
      );
    });

    test('yesterday is expired', () {
      expect(
        statusFor(DateTime(2026, 11, 17), now: now),
        ExpiryStatus.expired,
      );
    });

    test('long-expired is expired', () {
      expect(
        statusFor(DateTime(2020, 1, 1), now: now),
        ExpiryStatus.expired,
      );
    });

    test('custom threshold is honoured', () {
      expect(
        statusFor(
          DateTime(2026, 11, 25),
          now: now,
          soonThresholdDays: 5,
        ),
        ExpiryStatus.valid,
      );
      expect(
        statusFor(
          DateTime(2026, 11, 23),
          now: now,
          soonThresholdDays: 5,
        ),
        ExpiryStatus.expiringSoon,
      );
    });
  });

  group('daysRemainingText', () {
    final now = DateTime(2026, 11, 18);

    test('today', () {
      expect(
        daysRemainingText(DateTime(2026, 11, 18), now: now),
        'Expires today',
      );
    });

    test('tomorrow', () {
      expect(
        daysRemainingText(DateTime(2026, 11, 19), now: now),
        '1 day left',
      );
    });

    test('many days', () {
      expect(
        daysRemainingText(DateTime(2026, 12, 18), now: now),
        '30 days left',
      );
    });

    test('expired yesterday', () {
      expect(
        daysRemainingText(DateTime(2026, 11, 17), now: now),
        'Expired 1 day ago',
      );
    });

    test('expired long ago', () {
      expect(
        daysRemainingText(DateTime(2026, 10, 18), now: now),
        'Expired 31 days ago',
      );
    });
  });

  group('reminderDates', () {
    test('are 30, 7 and 1 day(s) before expiry, in order', () {
      final dates = reminderDates(DateTime(2026, 12, 18));
      expect(dates, <DateTime>[
        DateTime(2026, 11, 18),
        DateTime(2026, 12, 11),
        DateTime(2026, 12, 17),
      ]);
    });

    test('leap-year expiry gives correct reminder dates', () {
      final dates = reminderDates(DateTime(2028, 2, 29));
      expect(dates[0], DateTime(2028, 1, 30));
      expect(dates[1], DateTime(2028, 2, 22));
      expect(dates[2], DateTime(2028, 2, 28));
    });

    test('daysBeforeForReminder round-trips', () {
      final expiry = DateTime(2026, 12, 18);
      final dates = reminderDates(expiry);
      expect(
        dates.map((d) => daysBeforeForReminder(d, expiry)).toList(),
        <int>[30, 7, 1],
      );
    });

    test('pendingReminderDates drops dates already past', () {
      final pending = pendingReminderDates(
        DateTime(2026, 11, 25),
        now: DateTime(2026, 11, 18),
      );
      // 30-day reminder (Oct 26) is past; 7-day (Nov 18) and 1-day
      // (Nov 24) are still upcoming.
      expect(pending, <DateTime>[
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 24),
      ]);
    });

    test('pendingReminderDates is empty for an expired document', () {
      expect(
        pendingReminderDates(
          DateTime(2026, 11, 1),
          now: DateTime(2026, 11, 18),
        ),
        isEmpty,
      );
    });

    test('pendingReminderDates keeps all three for a far-future expiry', () {
      expect(
        pendingReminderDates(
          DateTime(2027, 6, 1),
          now: DateTime(2026, 11, 18),
        ).length,
        3,
      );
    });
  });

  group('statusLabel', () {
    test('labels', () {
      expect(statusLabel(ExpiryStatus.valid), 'Valid');
      expect(statusLabel(ExpiryStatus.expiringSoon), 'Expiring Soon');
      expect(statusLabel(ExpiryStatus.expired), 'Expired');
    });
  });
}
