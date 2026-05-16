import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'voice_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    bool voiceEnabled = false,
  }) async {
    if (!kIsWeb) {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'med_reminders',
          'Medication Reminders',
          channelDescription: 'Medication reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
      await _plugin.zonedSchedule(
        id,
        'Medication Reminder',
        'Time to take your $medicationName, $dosage',
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (voiceEnabled) {
      await VoiceService.instance.speak(
        'Time to take your $medicationName, $dosage',
      );
    }
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> scheduleMedicationReminders({
    required int medicationId,
    required String medicationName,
    required String dosage,
    required List<String> scheduledTimes,
    bool voiceEnabled = false,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'med_reminders',
        'Medication Reminders',
        channelDescription: 'Medication reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (var i = 0; i < scheduledTimes.length; i++) {
      final time = _parseTodayTime(scheduledTimes[i]);
      if (time == null) continue;
      var next = tz.TZDateTime.from(time, tz.local);
      if (next.isBefore(tz.TZDateTime.now(tz.local))) {
        next = next.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _notificationIdFor(medicationId, i),
        'Medication Reminder',
        voiceEnabled
            ? 'Voice reminder: Time to take your $medicationName, $dosage'
            : 'Time to take your $medicationName, $dosage',
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelMedicationReminders(int medicationId, int count) async {
    if (kIsWeb) return;
    await initialize();
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(_notificationIdFor(medicationId, i));
    }
  }

  int _notificationIdFor(int medicationId, int index) =>
      medicationId * 100 + index;

  DateTime? _parseTodayTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'med_instant',
        'Instant Alerts',
        channelDescription: 'Instant notifications and alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
