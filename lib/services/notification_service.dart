import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/document.dart';
import '../utils/expiry_logic.dart';

/// Local reminders: 30 days, 7 days and 1 day before a document expires,
/// delivered at 9:00am local time on each of those days.
///
/// Notifications are scheduled per document (id derived from the
/// document id + reminder offset) so editing or deleting a document can
/// cancel and reschedule exactly its own reminders.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  static const String _channelId = 'expiry_reminders';
  static const String _channelName = 'Expiry reminders';
  static const String _channelDescription =
      'Reminders before your documents expire';

  Future<void> initialise() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialised = true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  int _notificationId(int documentId, int daysBefore) =>
      documentId * 100 + daysBefore;

  /// Schedule the 30/7/1-day reminders for [doc]. Any still-future
  /// reminder dates are scheduled at 9:00am local time.
  Future<void> scheduleForDocument(ExpiryDocument doc) async {
    if (doc.id == null) return;
    await initialise();
    await cancelForDocument(doc);
    for (final reminderDate in pendingReminderDates(doc.expiryDate)) {
      final daysBefore = daysBeforeForReminder(reminderDate, doc.expiryDate);
      final when = tz.TZDateTime(
        tz.local,
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9,
      );
      if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: _notificationId(doc.id!, daysBefore),
        title: _titleFor(doc, daysBefore),
        body: _bodyFor(doc, daysBefore),
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  String _titleFor(ExpiryDocument doc, int daysBefore) {
    if (daysBefore <= 1) return '${doc.title} expires tomorrow';
    return '${doc.title} expires in $daysBefore days';
  }

  String _bodyFor(ExpiryDocument doc, int daysBefore) {
    final type = doc.type.label;
    if (daysBefore <= 1) {
      return 'Your $type (${doc.documentNumber}) expires tomorrow. '
          'Renew it to avoid a fine.';
    }
    return 'Your $type (${doc.documentNumber}) expires in '
        '$daysBefore days. Time to renew.';
  }

  Future<void> cancelForDocument(ExpiryDocument doc) async {
    if (doc.id == null) return;
    await initialise();
    for (final daysBefore in <int>[30, 7, 1]) {
      await _plugin.cancel(id: _notificationId(doc.id!, daysBefore));
    }
  }

  Future<void> rescheduleAll(List<ExpiryDocument> docs) async {
    for (final doc in docs) {
      await scheduleForDocument(doc);
    }
  }
}
