import 'dart:convert';

class MedicationModel {
  final int? id;
  final int userId;
  final String name;
  final String pillShape; // capsule|round|square
  final String pillColor; // hex
  final String dosageStrength;
  final String dosageUnit;
  final String frequency; // daily|weekly|custom
  final List<String> scheduledTimes; // JSON stored
  final String status; // active|paused
  final int refillCount;
  final String? notes;
  final List<String> tags; // JSON stored
  final DateTime createdAt;

  const MedicationModel({
    this.id,
    required this.userId,
    required this.name,
    required this.pillShape,
    required this.pillColor,
    required this.dosageStrength,
    required this.dosageUnit,
    required this.frequency,
    required this.scheduledTimes,
    required this.status,
    required this.refillCount,
    this.notes,
    required this.tags,
    required this.createdAt,
  });

  MedicationModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? pillShape,
    String? pillColor,
    String? dosageStrength,
    String? dosageUnit,
    String? frequency,
    List<String>? scheduledTimes,
    String? status,
    int? refillCount,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      pillShape: pillShape ?? this.pillShape,
      pillColor: pillColor ?? this.pillColor,
      dosageStrength: dosageStrength ?? this.dosageStrength,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      frequency: frequency ?? this.frequency,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      status: status ?? this.status,
      refillCount: refillCount ?? this.refillCount,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'pillShape': pillShape,
      'pillColor': pillColor,
      'dosageStrength': dosageStrength,
      'dosageUnit': dosageUnit,
      'frequency': frequency,
      'scheduledTimes': jsonEncode(scheduledTimes),
      'status': status,
      'refillCount': refillCount,
      'notes': notes,
      'tags': jsonEncode(tags),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(Map<String, Object?> map) {
    List<String> decodeList(Object? v) {
      if (v == null) return const [];
      try {
        final decoded = jsonDecode(v as String);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList(growable: false);
        }
      } catch (_) {}
      return const [];
    }

    return MedicationModel(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      pillShape: (map['pillShape'] as String?) ?? 'capsule',
      pillColor: (map['pillColor'] as String?) ?? '#00897B',
      dosageStrength: (map['dosageStrength'] as String?) ?? '',
      dosageUnit: (map['dosageUnit'] as String?) ?? '',
      frequency: (map['frequency'] as String?) ?? 'daily',
      scheduledTimes: decodeList(map['scheduledTimes']),
      status: (map['status'] as String?) ?? 'active',
      refillCount: (map['refillCount'] as int?) ?? 0,
      notes: map['notes'] as String?,
      tags: decodeList(map['tags']),
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

