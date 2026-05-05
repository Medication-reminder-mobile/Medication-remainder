import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/intake_log_model.dart';
import '../models/medication_model.dart';
import '../models/user_model.dart';

/// SQLite access layer. Other modules can extend this file or register
/// additional tables/migrations in [_onCreate].
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  static const String _dbName = 'medication_reminder.db';
  static const int _dbVersion = 2;

  Database? _db;
  final List<Map<String, Object?>> _webUsers = <Map<String, Object?>>[];
  int _webAutoIncrementId = 0;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database handle is not used on web.');
    }
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all core tables required by Member 1 deliverables.
  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createMedicationsTable(db);
    await _createIntakeLogsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createMedicationsTable(db);
      await _createIntakeLogsTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT
);
''');
  }

  Future<void> _createMedicationsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  shape TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  dosage_strength TEXT NOT NULL,
  frequency TEXT NOT NULL,
  time_of_day TEXT,
  voice_reminder INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  tags TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
''');
  }

  Future<void> _createIntakeLogsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS intake_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  medication_id INTEGER NOT NULL,
  scheduled_at TEXT NOT NULL,
  taken_at TEXT,
  status TEXT NOT NULL,
  notes TEXT,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
);
''');
  }

  /// Inserts a user; returns the new row id.
  Future<int> insertUser(UserModel user) async {
    if (kIsWeb) {
      final nextId = ++_webAutoIncrementId;
      _webUsers.add({
        'id': nextId,
        'name': user.name,
        'email': user.email.trim().toLowerCase(),
        'password': user.password,
        'role': user.role,
      });
      return nextId;
    }

    final db = await database;
    return db.insert(
      'users',
      {
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'role': user.role,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    if (kIsWeb) {
      final normalized = email.trim().toLowerCase();
      for (final row in _webUsers) {
        if ((row['email'] as String?) == normalized) {
          return UserModel.fromMap(row);
        }
      }
      return null;
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int id) async {
    if (kIsWeb) {
      for (final row in _webUsers) {
        if (row['id'] == id) {
          return UserModel.fromMap(row);
        }
      }
      return null;
    }

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

  Future<int> updateUserRole(int userId, String role) async {
    if (kIsWeb) {
      for (var i = 0; i < _webUsers.length; i++) {
        if (_webUsers[i]['id'] == userId) {
          _webUsers[i] = {
            ..._webUsers[i],
            'role': role,
          };
          return 1;
        }
      }
      return 0;
    }

    final db = await database;
    return db.update(
      'users',
      {'role': role},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserProfile({
    required int userId,
    required String name,
    required String email,
  }) async {
    if (kIsWeb) {
      for (var i = 0; i < _webUsers.length; i++) {
        if (_webUsers[i]['id'] == userId) {
          _webUsers[i] = {
            ..._webUsers[i],
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
          };
          return 1;
        }
      }
      return 0;
    }

    final db = await database;
    return db.update(
      'users',
      {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
      },
      where: 'id = ?',
      whereArgs: [userId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> insertMedication(MedicationModel medication) async {
    if (kIsWeb) {
      throw UnsupportedError('Medication persistence is not enabled on web.');
    }
    final db = await database;
    return db.insert(
      'medications',
      medication.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<MedicationModel?> getMedicationById(int medicationId) async {
    if (kIsWeb) {
      return null;
    }
    final db = await database;
    final rows = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MedicationModel.fromMap(rows.first);
  }

  Future<List<MedicationModel>> getMedicationsByUser(int userId) async {
    if (kIsWeb) {
      return const <MedicationModel>[];
    }
    final db = await database;
    final rows = await db.query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(MedicationModel.fromMap).toList();
  }

  Future<int> updateMedication(MedicationModel medication) async {
    if (kIsWeb) {
      return 0;
    }
    final id = medication.id;
    if (id == null) {
      throw ArgumentError('Medication id is required for update.');
    }
    final db = await database;
    final payload = medication.copyWith(updatedAt: DateTime.now()).toMap()
      ..remove('id');
    return db.update(
      'medications',
      payload,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedication(int medicationId) async {
    if (kIsWeb) {
      return 0;
    }
    final db = await database;
    return db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<int> insertIntakeLog(IntakeLogModel log) async {
    if (kIsWeb) {
      throw UnsupportedError('Intake log persistence is not enabled on web.');
    }
    final db = await database;
    return db.insert(
      'intake_logs',
      log.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<IntakeLogModel>> getIntakeLogsForDate({
    required int userId,
    required DateTime date,
  }) async {
    if (kIsWeb) {
      return const <IntakeLogModel>[];
    }
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final db = await database;
    final rows = await db.query(
      'intake_logs',
      where: 'user_id = ? AND scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(IntakeLogModel.fromMap).toList();
  }

  Future<int> updateIntakeLogStatus({
    required int logId,
    required String status,
    DateTime? takenAt,
  }) async {
    if (kIsWeb) {
      return 0;
    }
    final db = await database;
    return db.update(
      'intake_logs',
      {
        'status': status,
        'taken_at': takenAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  /// Call on logout if you want to release the DB handle (optional).
  Future<void> close() async {
    if (kIsWeb) {
      return;
    }
    await _db?.close();
    _db = null;
  }
}
