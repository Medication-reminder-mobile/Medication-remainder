import 'package:flutter/material.dart';

import '../models/caregiver_task_model.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';

class CaregiverProvider extends ChangeNotifier {
  CaregiverProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<UserModel> linkedPatients = [];
  List<CaregiverTaskModel> tasks = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadLinkedPatients(int caregiverId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      linkedPatients = await _db.getLinkedPatients(caregiverId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> linkPatient(int caregiverId, String patientEmail) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final patient = await _db.getUserByEmail(patientEmail.trim().toLowerCase());
      if (patient == null || patient.id == null) {
        errorMessage = 'No patient found for that email';
        return;
      }
      final already = await _db.isAlreadyLinked(caregiverId, patient.id!);
      if (already) {
        errorMessage = 'Patient already linked';
        return;
      }
      await _db.linkCaregiverToPatient(caregiverId, patient.id!, editPermission: false);
      linkedPatients = [patient, ...linkedPatients];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks(int caregiverId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tasks = await _db.getTasksByCaregiver(caregiverId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTask(int taskId, bool isDone) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.toggleTaskDone(taskId, isDone);
      tasks = tasks
          .map((t) => t.id == taskId ? t.copyWith(isDone: isDone) : t)
          .toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

