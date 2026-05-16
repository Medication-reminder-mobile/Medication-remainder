import 'package:flutter/material.dart';

import '../models/rbc_entry_model.dart';
import '../services/db_service.dart';

class RbcProvider extends ChangeNotifier {
  RbcProvider({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  List<RbcEntryModel> entries = [];
  bool isLoading = false;
  String? errorMessage;

  // FIX: keep last deleted for potential undo
  RbcEntryModel? _lastDeleted;
  RbcEntryModel? get lastDeleted => _lastDeleted;

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
    // FIX: do NOT set isLoading=true for delete — it was causing the black
    // screen because the whole list re-rendered into shimmer/loading state
    // while the delete was in progress. Instead update optimistically.
    errorMessage = null;

    // Optimistic removal — remove from list immediately
    final target = entries.where((e) => e.id == id).firstOrNull;
    if (target == null) return;
    _lastDeleted = target;
    entries = entries.where((e) => e.id != id).toList(growable: false);
    notifyListeners();

    try {
      await _db.deleteRbcEntry(id);
    } catch (e) {
      // FIX: if DB delete fails, restore the entry
      errorMessage = e.toString();
      entries = [target, ...entries];
      _lastDeleted = null;
      notifyListeners();
    }
  }

  /// Undo the last deletion by re-inserting the entry.
  Future<void> undoDelete(int userId) async {
    final entry = _lastDeleted;
    if (entry == null) return;
    _lastDeleted = null;
    await addEntry(entry.copyWith(id: null));
  }

  /// Latest entry, or null if none.
  RbcEntryModel? get latest => entries.isEmpty ? null : entries.first;
}