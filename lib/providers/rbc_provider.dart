import 'package:flutter/material.dart';

import '../models/rbc_entry_model.dart';
import '../services/db_service.dart';

class RbcProvider extends ChangeNotifier {
  RbcProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<RbcEntryModel> entries = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadEntries(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      entries = await _db.getRbcEntriesByUser(userId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(RbcEntryModel entry) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final id = await _db.insertRbcEntry(entry);
      entries = [entry.copyWith(id: id), ...entries];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.deleteRbcEntry(id);
      entries = entries.where((e) => e.id != id).toList(growable: false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Latest entry, or null if none.
  RbcEntryModel? get latest => entries.isEmpty ? null : entries.first;
}
