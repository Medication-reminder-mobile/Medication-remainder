import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class SessionService {
  static const _kUserId = 'session_user_id';
  static const _kName = 'session_name';
  static const _kEmail = 'session_email';
  static const _kPasswordHash = 'session_password_hash';
  static const _kRole = 'session_role';
  static const _kAvatarPath = 'session_avatar_path';
  static const _kIsPremium = 'session_is_premium';
  static const _kCreatedAt = 'session_created_at';

  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUserId, user.id ?? -1);
    await prefs.setString(_kName, user.name);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kPasswordHash, user.passwordHash);
    await prefs.setString(_kRole, user.role);
    if (user.avatarPath != null) {
      await prefs.setString(_kAvatarPath, user.avatarPath!);
    } else {
      await prefs.remove(_kAvatarPath);
    }
    await prefs.setBool(_kIsPremium, user.isPremium);
    await prefs.setString(_kCreatedAt, user.createdAt.toIso8601String());
  }

  Future<UserModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kUserId);
    if (id == null || id < 0) return null;
    final name = prefs.getString(_kName);
    final email = prefs.getString(_kEmail);
    final hash = prefs.getString(_kPasswordHash);
    final role = prefs.getString(_kRole);
    final createdAt = prefs.getString(_kCreatedAt);
    if (name == null || email == null || hash == null || role == null || createdAt == null) {
      return null;
    }
    return UserModel(
      id: id,
      name: name,
      email: email,
      passwordHash: hash,
      role: role,
      avatarPath: prefs.getString(_kAvatarPath),
      isPremium: prefs.getBool(_kIsPremium) ?? false,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPasswordHash);
    await prefs.remove(_kRole);
    await prefs.remove(_kAvatarPath);
    await prefs.remove(_kIsPremium);
    await prefs.remove(_kCreatedAt);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kUserId);
    return id != null && id >= 0;
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }
}

