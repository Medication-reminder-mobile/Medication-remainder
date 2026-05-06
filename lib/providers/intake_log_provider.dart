import 'package:flutter/material.dart';

import '../core/utils/date_helpers.dart';
import '../models/intake_log_model.dart';
import '../services/db_service.dart';

class IntakeLogProvider extends ChangeNotifier {
  IntakeLogProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<IntakeLogModel> todayLogs = [];
  double adherenceRate = 0;
  int currentStreak = 0;

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadTodayLogs(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      todayLogs = await _db.getLogsByUserAndDate(
        userId,
        DateHelpers.ymd(DateTime.now()),
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markTaken(IntakeLogModel log) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = log.copyWith(status: 'taken', takenAt: DateTime.now());
      await _db.updateIntakeLog(updated);
      todayLogs = todayLogs
          .map((l) => l.id == updated.id ? updated : l)
          .toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markMissed(IntakeLogModel log) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = log.copyWith(status: 'missed', takenAt: null);
      await _db.updateIntakeLog(updated);
      todayLogs = todayLogs
          .map((l) => l.id == updated.id ? updated : l)
          .toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logAll(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final upcoming = todayLogs.where((l) => l.status == 'upcoming').toList();
      for (final log in upcoming) {
        final updated = log.copyWith(status: 'taken', takenAt: DateTime.now());
        await _db.updateIntakeLog(updated);
        todayLogs = todayLogs
            .map((l) => l.id == updated.id ? updated : l)
            .toList(growable: false);
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdherenceStats(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      adherenceRate = await _db.getAdherenceRate(userId, days: 7);
      currentStreak = await _db.getCurrentStreak(userId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
