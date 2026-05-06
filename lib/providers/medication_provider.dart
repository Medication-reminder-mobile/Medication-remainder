import 'package:flutter/material.dart';

import '../core/utils/date_helpers.dart';
import '../models/intake_log_model.dart';
import '../models/medication_model.dart';
import '../services/db_service.dart';

class MedicationProvider extends ChangeNotifier {
  MedicationProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<MedicationModel> medications = [];
  bool isLoading = false;
  String? errorMessage;

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
      await _db.updateMedication(med);
      medications = medications
          .map((m) => m.id == med.id ? med : m)
          .toList(growable: false);
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
    try {
      await _db.deleteMedication(id);
      medications = medications
          .where((m) => m.id != id)
          .toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(int id, String status) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.updateMedicationStatus(id, status);
      medications = medications
          .map((m) => m.id == id ? m.copyWith(status: status) : m)
          .toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
