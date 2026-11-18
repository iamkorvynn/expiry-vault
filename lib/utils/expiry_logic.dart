/// Pure expiry math for ExpiryVault.
///
/// Kept free of Flutter / plugin imports so it is trivially unit-testable.
/// All calculations are date-only (time of day is ignored) so that a
/// document expiring "today" is unambiguous.
library;

enum ExpiryStatus { valid, expiringSoon, expired }

/// The number of whole days from [now] until [expiry], date-only.
///
/// Positive = still valid, 0 = expires today, negative = already expired.
int daysRemaining(DateTime expiry, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(expiry);
  return target.difference(today).inDays;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Classify an expiry date.
///
/// * [expired] — days remaining < 0
/// * [expiringSoon] — 0 <= days remaining <= [soonThresholdDays] (default 30)
/// * [valid] — anything further out
ExpiryStatus statusFor(
  DateTime expiry, {
  DateTime? now,
  int soonThresholdDays = 30,
}) {
  final days = daysRemaining(expiry, now: now);
  if (days < 0) return ExpiryStatus.expired;
  if (days <= soonThresholdDays) return ExpiryStatus.expiringSoon;
  return ExpiryStatus.valid;
}

/// Human-readable label for a status.
String statusLabel(ExpiryStatus status) => switch (status) {
      ExpiryStatus.valid => 'Valid',
      ExpiryStatus.expiringSoon => 'Expiring Soon',
      ExpiryStatus.expired => 'Expired',
    };

/// Short human text for the days-remaining counter.
String daysRemainingText(DateTime expiry, {DateTime? now}) {
  final days = daysRemaining(expiry, now: now);
  if (days < 0) {
    final n = -days;
    return n == 1 ? 'Expired 1 day ago' : 'Expired $n days ago';
  }
  if (days == 0) return 'Expires today';
  if (days == 1) return '1 day left';
  return '$days days left';
}

/// The three reminder moments for an expiry date: 30, 7 and 1 day(s)
/// before expiry. Returned in chronological order.
List<DateTime> reminderDates(DateTime expiry) {
  final target = _dateOnly(expiry);
  return <DateTime>[
    target.subtract(const Duration(days: 30)),
    target.subtract(const Duration(days: 7)),
    target.subtract(const Duration(days: 1)),
  ];
}

/// The reminder dates that are still in the future (today counts as
/// upcoming — a reminder scheduled for today at 9am may still fire).
List<DateTime> pendingReminderDates(DateTime expiry, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  return reminderDates(
    expiry,
  ).where((d) => !d.isBefore(today)).toList(growable: false);
}

/// How many days before expiry a given reminder date is (30, 7 or 1).
int daysBeforeForReminder(DateTime reminder, DateTime expiry) =>
    _dateOnly(expiry).difference(_dateOnly(reminder)).inDays;
