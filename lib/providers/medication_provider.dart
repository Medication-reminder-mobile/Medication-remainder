import 'package:flutter/material.dart';

import '../core/utils/date_helpers.dart';
import '../models/intake_log_model.dart';
import '../models/medication_model.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  MedicationProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<MedicationModel> medications = [];
  bool isLoading = false;
  String? errorMessage;

  // FIX: keep a deleted item so the UI can offer undo without crashing
  MedicationModel? _lastDeleted;
  MedicationModel? get lastDeleted => _lastDeleted;

  Future<void> loadMedications(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      medications = await _db.getMedicationsByUser(userId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(MedicationModel med) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final id = await _db.insertMedication(med);
      final saved = med.copyWith(id: id);
      medications = [saved, ...medications];

      // Auto-generate today's intake logs for each scheduled time
      final today = DateHelpers.ymd(DateTime.now());
      for (final time in saved.scheduledTimes) {
        final log = IntakeLogModel(
          id: null,
          medicationId: id,
          userId: saved.userId,
          scheduledTime: time,
          takenAt: null,
          status: 'upcoming',
          date: today,
        );
        await _db.insertIntakeLog(log);
      }
      await _scheduleForMedication(saved);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedication(MedicationModel med) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final old = _findMedicationById(med.id);
      if (old?.id != null) {
        await NotificationService.instance.cancelMedicationReminders(
          old!.id!,
          old.scheduledTimes.length,
        );
      }
      await _db.updateMedication(med);
      medications = medications
          .map((m) => m.id == med.id ? med : m)
          .toList(growable: false);
      await _scheduleForMedication(med);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final old = _findMedicationById(id);
    if (old != null) {
      // FIX: save for undo before removing
      _lastDeleted = old;
      await NotificationService.instance.cancelMedicationReminders(
        id,
        old.scheduledTimes.length,
      );
    }

    medications = medications.where((m) => m.id != id).toList(growable: false);
    notifyListeners();

    try {
      await _db.deleteMedication(id);
    } catch (e) {
      errorMessage = e.toString();
      if (old != null) {
        medications = [old, ...medications];
      }
      _lastDeleted = null;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // FIX: undo delete — re-inserts the medication into DB and list
  Future<void> undoDelete() async {
    final med = _lastDeleted;
    if (med == null) return;
    _lastDeleted = null;
    await addMedication(med.copyWith(id: null));
  }

  // FIX: toggleStatus now correctly updates both DB and in-memory list
  Future<void> toggleStatus(int id, String status) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.updateMedicationStatus(id, status);
      // Update local list immediately so the UI reflects the change
      medications = medications
          .map((m) => m.id == id ? m.copyWith(status: status) : m)
          .toList(growable: false);

      final updated = _findMedicationById(id);
      if (updated != null) {
        if (status == 'paused') {
          await NotificationService.instance.cancelMedicationReminders(
            id,
            updated.scheduledTimes.length,
          );
        } else if (status == 'active') {
          await _scheduleForMedication(updated);
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleForMedication(MedicationModel med) async {
    final medId = med.id;
    if (medId == null || med.status != 'active') return;
    await NotificationService.instance.scheduleMedicationReminders(
      medicationId: medId,
      medicationName: med.name,
      dosage: '${med.dosageStrength}${med.dosageUnit}',
      scheduledTimes: med.scheduledTimes,
      voiceEnabled: _isVoiceEnabled(med),
    );
  }

  bool _isVoiceEnabled(MedicationModel med) =>
      med.tags.contains('voice_enabled');

  MedicationModel? _findMedicationById(int? id) {
    if (id == null) return null;
    for (final med in medications) {
      if (med.id == id) return med;
    }
    return null;
  }
}
