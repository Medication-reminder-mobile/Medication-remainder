enum UserRole {
  individualUser('individual_user'),
  individualCaregiver('individual_caregiver'),
  professionalCaregiver('professional_caregiver');

  const UserRole(this.value);
  final String value;

  static UserRole? fromValue(String value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String role; // individual_user | individual_caregiver | professional_caregiver
  final String? avatarPath;
  final bool isPremium;
  final DateTime createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.avatarPath,
    required this.isPremium,
    required this.createdAt,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? avatarPath,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'avatarPath': avatarPath,
      'isPremium': isPremium ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      passwordHash: (map['passwordHash'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
      avatarPath: map['avatarPath'] as String?,
      isPremium: ((map['isPremium'] as int?) ?? 0) == 1,
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  UserRole? get roleEnum => UserRole.fromValue(role);
}

