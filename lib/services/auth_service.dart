import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/user_model.dart';
import 'db_service.dart';
import 'session_service.dart';

class AuthService {
  AuthService({
    DbService? db,
    SessionService? session,
  })  : _db = db ?? DbService.instance,
        _session = session ?? SessionService();

  final DbService _db;
  final SessionService _session;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserModel?> register(String name, String email, String password, String role) async {
    final existing = await _db.getUserByEmail(email.trim().toLowerCase());
    if (existing != null) return null;

    final user = UserModel(
      id: null,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: _hashPassword(password),
      role: role,
      avatarPath: null,
      isPremium: false,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertUser(user);
    final created = user.copyWith(id: id);
    await _session.saveSession(created);
    return created;
  }

  Future<UserModel?> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final user = await _db.getUserByEmail(email.trim().toLowerCase());
    if (user == null) return null;
    final hash = _hashPassword(password);
    if (hash != user.passwordHash) return null;
    if (rememberMe) {
      await _session.saveSession(user);
    } else {
      await _session.clearSession();
    }
    return user;
  }

  Future<void> logout() async {
    await _session.clearSession();
  }
}

