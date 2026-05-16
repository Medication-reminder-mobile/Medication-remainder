import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import '../core/utils/date_helpers.dart';
import '../models/caregiver_task_model.dart';
import '../models/doctor_note_model.dart';
import '../models/intake_log_model.dart';
import '../models/medication_model.dart';
import '../models/rbc_entry_model.dart';
import '../models/user_model.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  static const _dbName = 'medremind.db';
  static const _dbVersion = 2;

  sqflite.Database? _db;
  Future<sqflite.Database>? _openingDb;
  bool _factoryConfigured = false;

  Future<sqflite.Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opening = _openingDb;
    if (opening != null) return opening;

    final initFuture = _init();
    _openingDb = initFuture;
    try {
      final db = await initFuture;
      _db = db;
      return db;
    } finally {
      _openingDb = null;
    }
  }

  Future<sqflite.Database> _init() async {
    _configureDatabaseFactory();

    late final String path;
    if (kIsWeb) {
      path = _dbName;
    } else {
      // Use the active database factory so desktop FFI resolves correctly.
      final dbPath = await sqflite.databaseFactory.getDatabasesPath();
      path = p.join(dbPath, _dbName);
    }
    return sqflite.openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  passwordHash TEXT NOT NULL,
  role TEXT NOT NULL,
  avatarPath TEXT,
  isPremium INTEGER NOT NULL,
  createdAt TEXT NOT NULL
)
''');

        await db.execute('''
CREATE TABLE medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  name TEXT NOT NULL,
  pillShape TEXT NOT NULL,
  pillColor TEXT NOT NULL,
  dosageStrength TEXT NOT NULL,
  dosageUnit TEXT NOT NULL,
  frequency TEXT NOT NULL,
  scheduledTimes TEXT NOT NULL,
  status TEXT NOT NULL,
  refillCount INTEGER NOT NULL,
  notes TEXT,
  tags TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');

        await db.execute('''
CREATE TABLE intake_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicationId INTEGER NOT NULL,
  userId INTEGER NOT NULL,
  scheduledTime TEXT NOT NULL,
  takenAt TEXT,
  status TEXT NOT NULL,
  date TEXT NOT NULL
)
''');

        await db.execute('''
CREATE TABLE caregiver_patients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  caregiverId INTEGER NOT NULL,
  patientId INTEGER NOT NULL,
  editPermission INTEGER NOT NULL,
  linkedAt TEXT NOT NULL,
  UNIQUE(caregiverId, patientId)
)
''');

        await db.execute('''
CREATE TABLE caregiver_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  caregiverId INTEGER NOT NULL,
  patientId INTEGER,
  description TEXT NOT NULL,
  priority TEXT NOT NULL,
  isDone INTEGER NOT NULL,
  createdAt TEXT NOT NULL
)
''');

        await db.execute('''
CREATE TABLE doctor_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  patientId INTEGER NOT NULL,
  note TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');

        await _createRbcTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createRbcTable(db);
        }
      },
    );
  }

  void _configureDatabaseFactory() {
    if (_factoryConfigured) return;

    if (!kIsWeb) {
      final isDesktop =
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (isDesktop) {
        sqfliteFfiInit();
        sqflite.databaseFactory = databaseFactoryFfi;
      }
      // On Android/iOS, sqflite works natively — no factory override needed.
    }

    _factoryConfigured = true;
  }

  // Users
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    if (user.id == null) return;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Medications
  Future<int> insertMedication(MedicationModel med) async {
    final db = await database;
    return db.insert(
      'medications',
      med.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<MedicationModel>> getMedicationsByUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'medications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(MedicationModel.fromMap).toList(growable: false);
  }

  Future<MedicationModel?> getMedicationById(int id) async {
    final db = await database;
    final rows = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MedicationModel.fromMap(rows.first);
  }

  Future<void> updateMedication(MedicationModel med) async {
    final db = await database;
    if (med.id == null) return;
    await db.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  Future<void> deleteMedication(int id) async {
    final db = await database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMedicationStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'medications',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Intake logs
  Future<int> insertIntakeLog(IntakeLogModel log) async {
    final db = await database;
    return db.insert(
      'intake_logs',
      log.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<IntakeLogModel>> getLogsByUserAndDate(
    int userId,
    String date,
  ) async {
    final db = await database;
    final rows = await db.query(
      'intake_logs',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, date],
      orderBy: 'scheduledTime ASC',
    );
    return rows.map(IntakeLogModel.fromMap).toList(growable: false);
  }

  Future<List<IntakeLogModel>> getLogsByUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'intake_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, scheduledTime ASC',
    );
    return rows.map(IntakeLogModel.fromMap).toList(growable: false);
  }

  Future<void> updateIntakeLog(IntakeLogModel log) async {
    final db = await database;
    if (log.id == null) return;
    await db.update(
      'intake_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<double> getAdherenceRate(int userId, {int days = 7}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final sinceStr = DateHelpers.ymd(since);
    final rows = await db.rawQuery(
      '''
SELECT
  SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) as takenCount,
  COUNT(*) as totalCount
FROM intake_logs
WHERE userId = ? AND date >= ?
''',
      [userId, sinceStr],
    );

    final taken = (rows.first['takenCount'] as int?) ?? 0;
    final total = (rows.first['totalCount'] as int?) ?? 0;
    if (total == 0) return 0;
    return taken / total;
  }

  Future<Map<String, int>> getMonthlyStats(
    int userId,
    int year,
    int month,
  ) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final startStr = DateHelpers.ymd(start);
    final endStr = DateHelpers.ymd(end);

    final rows = await db.rawQuery(
      '''
SELECT date,
  SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) as takenCount,
  SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missedCount,
  COUNT(*) as totalCount
FROM intake_logs
WHERE userId = ? AND date >= ? AND date <= ?
GROUP BY date
''',
      [userId, startStr, endStr],
    );

    var perfect = 0;
    var partial = 0;
    var missed = 0;

    for (final r in rows) {
      final taken = (r['takenCount'] as int?) ?? 0;
      final miss = (r['missedCount'] as int?) ?? 0;
      final total = (r['totalCount'] as int?) ?? 0;
      if (total == 0) continue;
      if (miss == 0 && taken == total) {
        perfect++;
      } else if (taken > 0) {
        partial++;
      } else {
        missed++;
      }
    }

    return {'perfect': perfect, 'partial': partial, 'missed': missed};
  }

  Future<int> getCurrentStreak(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
SELECT date,
  SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missedCount,
  COUNT(*) as totalCount
FROM intake_logs
WHERE userId = ?
GROUP BY date
ORDER BY date DESC
''',
      [userId],
    );

    var streak = 0;
    for (final r in rows) {
      final missed = (r['missedCount'] as int?) ?? 0;
      final total = (r['totalCount'] as int?) ?? 0;
      if (total == 0) continue;
      if (missed == 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // CaregiverPatients
  Future<void> linkCaregiverToPatient(
    int caregiverId,
    int patientId, {
    bool editPermission = false,
  }) async {
    final db = await database;
    await db.insert('caregiver_patients', {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'editPermission': editPermission ? 1 : 0,
      'linkedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
  }

  Future<List<UserModel>> getLinkedPatients(int caregiverId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
SELECT u.*
FROM caregiver_patients cp
JOIN users u ON u.id = cp.patientId
WHERE cp.caregiverId = ?
ORDER BY cp.linkedAt DESC
''',
      [caregiverId],
    );
    return rows
        .map((e) => UserModel.fromMap(Map<String, Object?>.from(e)))
        .toList(growable: false);
  }

  Future<bool> isAlreadyLinked(int caregiverId, int patientId) async {
    final db = await database;
    final rows = await db.query(
      'caregiver_patients',
      columns: ['id'],
      where: 'caregiverId = ? AND patientId = ?',
      whereArgs: [caregiverId, patientId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> unlinkPatient(int caregiverId, int patientId) async {
    final db = await database;
    await db.delete(
      'caregiver_patients',
      where: 'caregiverId = ? AND patientId = ?',
      whereArgs: [caregiverId, patientId],
    );
  }

  Future<List<UserModel>> getCaregiversForPatient(int patientId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
SELECT u.*
FROM caregiver_patients cp
JOIN users u ON u.id = cp.caregiverId
WHERE cp.patientId = ?
ORDER BY cp.linkedAt DESC
''',
      [patientId],
    );
    return rows
        .map((e) => UserModel.fromMap(Map<String, Object?>.from(e)))
        .toList(growable: false);
  }

  // CaregiverTasks
  Future<int> insertTask(CaregiverTaskModel task) async {
    final db = await database;
    return db.insert(
      'caregiver_tasks',
      task.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<CaregiverTaskModel>> getTasksByCaregiver(int caregiverId) async {
    final db = await database;
    final rows = await db.query(
      'caregiver_tasks',
      where: 'caregiverId = ?',
      whereArgs: [caregiverId],
      orderBy: 'isDone ASC, createdAt DESC',
    );
    return rows.map(CaregiverTaskModel.fromMap).toList(growable: false);
  }

  Future<void> toggleTaskDone(int taskId, bool isDone) async {
    final db = await database;
    await db.update(
      'caregiver_tasks',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.delete('caregiver_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // DoctorNotes
  Future<int> insertDoctorNote(DoctorNoteModel note) async {
    final db = await database;
    return db.insert(
      'doctor_notes',
      note.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<DoctorNoteModel>> getNotesByPatient(int patientId) async {
    final db = await database;
    final rows = await db.query(
      'doctor_notes',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(DoctorNoteModel.fromMap).toList(growable: false);
  }

  Future<void> deleteDoctorNote(int id) async {
    final db = await database;
    await db.delete('doctor_notes', where: 'id = ?', whereArgs: [id]);
  }

  // ── RBC Entries ──────────────────────────────────────────────────────────

  static Future<void> _createRbcTable(sqflite.Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS rbc_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  rbcCount REAL NOT NULL,
  hemoglobin REAL NOT NULL,
  hematocrit REAL NOT NULL,
  mcv REAL NOT NULL,
  note TEXT,
  recordedAt TEXT NOT NULL
)
''');
  }

  Future<int> insertRbcEntry(RbcEntryModel entry) async {
    final db = await database;
    return db.insert(
      'rbc_entries',
      entry.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<RbcEntryModel>> getRbcEntriesByUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'rbc_entries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'recordedAt DESC',
    );
    return rows.map(RbcEntryModel.fromMap).toList(growable: false);
  }

  Future<void> deleteRbcEntry(int id) async {
    final db = await database;
    await db.delete('rbc_entries', where: 'id = ?', whereArgs: [id]);
  }
}
