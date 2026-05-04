/// Local user record stored in SQLite (Member 1 — auth & profile).
///
/// [role] is `UserModel.roleUser`, `UserModel.roleCaregiver`, or null until
/// the user completes role selection after register/login.
class UserModel {
  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role,
  });

  static const String roleUser = 'user';
  static const String roleCaregiver = 'caregiver';

  final int? id;
  final String name;
  final String email;
  final String password;
  final String? role;

  bool get hasRole =>
      role != null &&
      role!.isNotEmpty &&
      (role == roleUser || role == roleCaregiver);

  String get roleDisplayLabel {
    if (role == roleCaregiver) return 'Caregiver';
    if (role == roleUser) return 'User';
    return 'Not set';
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, Object?> map) {
    final rawId = map['id'];
    int? id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is num) {
      id = rawId.toInt();
    }

    return UserModel(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String?,
    );
  }
}
