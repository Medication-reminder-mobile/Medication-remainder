import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

/// SQLite access layer. Other modules can extend this file or register
/// additional tables/migrations in [_onCreate].
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  static const String _dbName = 'medication_reminder.db';
  static const int _dbVersion = 1;

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
    );
  }

  /// Creates the `users` table used by [AuthService].
  Future<void> _onCreate(Database db, int version) async {
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

  /// Call on logout if you want to release the DB handle (optional).
  Future<void> close() async {
    if (kIsWeb) {
      return;
    }
    await _db?.close();
    _db = null;
  }
}
