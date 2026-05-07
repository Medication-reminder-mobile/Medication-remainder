import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/utils/date_helpers.dart';
import 'db_service.dart';
import 'notification_service.dart';
import 'voice_service.dart';

class WorkManagerService {
  WorkManagerService._();
  static final WorkManagerService instance = WorkManagerService._();

  static const String checkMedicationsTask = 'checkMedicationsTask';

  Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      'medremind_periodic',
      checkMedicationsTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == WorkManagerService.checkMedicationsTask) {
      final now = DateTime.now();
      final today = DateHelpers.ymd(now);

      // We don't know the user in background; best-effort: notify for any upcoming logs for any user.
      // In a real app you'd scope this to session user or registered medications.
      final db = DbService.instance;
      final notif = NotificationService.instance;
      await notif.initialize();
      await VoiceService.instance.initialize();

      final database = await db.database;
      final rows = await database.rawQuery(
        '''
SELECT il.id as logId,
       il.scheduledTime as scheduledTime,
       il.date as date,
       m.name as medName,
       m.dosageStrength as strength,
       m.dosageUnit as unit,
       m.status as medStatus,
       m.tags as tags
FROM intake_logs il
JOIN medications m ON m.id = il.medicationId
WHERE il.status = 'upcoming' AND il.date = ? AND m.status = 'active'
''',
        [today],
      );

      for (final r in rows) {
        final scheduled = (r['scheduledTime'] as String?) ?? '00:00';
        final due = DateHelpers.combineDateAndTime(now, scheduled);
        final diff = due.difference(now).inMinutes;
        if (diff >= 0 && diff <= 15) {
          final med = (r['medName'] as String?) ?? 'medication';
          final dose =
              '${(r['strength'] as String?) ?? ''}${(r['unit'] as String?) ?? ''}'
                  .trim();
          final tags = (r['tags'] as String?) ?? '[]';
          final voiceEnabled = tags.contains('voice_enabled');

          await notif.showInstantNotification(
            'Upcoming dose',
            'In $diff min: $med ${dose.isEmpty ? '' : '($dose)'}',
          );

          if (voiceEnabled && diff <= 1) {
            await VoiceService.instance.speakForced(
              'Time to take your $med ${dose.isEmpty ? '' : dose}',
            );
          }
        }
      }
    }
    return true;
  });
}
