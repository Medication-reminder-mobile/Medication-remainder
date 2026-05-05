import 'package:flutter/foundation.dart';

import '../models/medication_model.dart';

/// Notification scheduling facade for medication reminders.
///
/// Teammates can call this API now; plugin wiring can be added later without
/// changing feature-layer code.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    // Placeholder initialization point for local notification plugin setup.
    _initialized = true;
  }

  Future<void> scheduleMedicationReminder(MedicationModel medication) async {
    if (!_initialized) {
      await initialize();
    }
    if (kDebugMode) {
      debugPrint(
        'schedule reminder -> medication_id=${medication.id} time=${medication.timeOfDay}',
      );
    }
  }

  Future<void> cancelMedicationReminder(int medicationId) async {
    if (!_initialized) return;
    if (kDebugMode) {
      debugPrint('cancel reminder -> medication_id=$medicationId');
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    if (kDebugMode) {
      debugPrint('cancel all reminders');
    }
  }
}
