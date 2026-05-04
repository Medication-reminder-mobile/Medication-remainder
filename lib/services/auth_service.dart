import '../models/user_model.dart';
import 'db_service.dart';

/// In-app session + auth operations backed by SQLite.
///
/// Session is held in memory for the app lifetime; on cold start the user
/// signs in again. Teammates can later plug in `shared_preferences` or tokens.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _current;

  UserModel? get currentUser => _current;
  bool get isLoggedIn => _current != null;

  /// Basic non-empty checks and a simple email pattern.
  static bool isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v);
  }

  static String? validateEmailField(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!isValidEmail(v)) return 'Enter a valid email';
    return null;
  }

  static String? validatePasswordField(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateNameField(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    return null;
  }

  /// Registers a new user (password stored locally per project spec).
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await DbService.instance.getUserByEmail(normalizedEmail);
    if (existing != null) {
      throw AuthException('An account already exists for this email');
    }

    final user = UserModel(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      role: null,
    );
    final id = await DbService.instance.insertUser(user);
    _current = user.copyWith(id: id);
    return _current!;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final row = await DbService.instance.getUserByEmail(normalizedEmail);
    if (row == null) {
      throw AuthException('No account found for this email');
    }
    if (row.password != password) {
      throw AuthException('Incorrect password');
    }
    _current = row;
    return _current!;
  }

  void logout() {
    _current = null;
  }

  /// Persists role and refreshes the in-memory [currentUser].
  Future<void> setRole(String role) async {
    final u = _current;
    if (u?.id == null) {
      throw AuthException('Not signed in');
    }
    if (role != UserModel.roleUser && role != UserModel.roleCaregiver) {
      throw AuthException('Invalid role');
    }
    await DbService.instance.updateUserRole(u!.id!, role);
    final fresh = await DbService.instance.getUserById(u.id!);
    _current = fresh ?? u.copyWith(role: role);
  }

  /// Reload user from DB (e.g. after another screen updates profile).
  Future<void> refreshCurrentUser() async {
    final id = _current?.id;
    if (id == null) return;
    final fresh = await DbService.instance.getUserById(id);
    if (fresh != null) {
      _current = fresh;
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    final u = _current;
    if (u?.id == null) {
      throw AuthException('Not signed in');
    }

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final nameError = validateNameField(cleanName);
    if (nameError != null) throw AuthException(nameError);
    final emailError = validateEmailField(cleanEmail);
    if (emailError != null) throw AuthException(emailError);
    final currentUser = u!;

    try {
      final ownerOfEmail = await DbService.instance.getUserByEmail(cleanEmail);
      if (ownerOfEmail != null && ownerOfEmail.id != currentUser.id) {
        throw AuthException('That email is already used by another account');
      }

      final updated = await DbService.instance.updateUserProfile(
        userId: currentUser.id!,
        name: cleanName,
        email: cleanEmail,
      );
      if (updated == 0) {
        throw AuthException('Could not update profile. Please try again.');
      }
      final fresh = await DbService.instance.getUserById(currentUser.id!);
      final next = fresh ??
          currentUser.copyWith(name: cleanName, email: cleanEmail);
      _current = next;
      return next;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('Could not update profile. Please try again.');
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
