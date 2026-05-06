class CaregiverTaskModel {
  final int? id;
  final int caregiverId;
  final int? patientId;
  final String description;
  final String priority; // low|medium|high
  final bool isDone;
  final DateTime createdAt;

  const CaregiverTaskModel({
    this.id,
    required this.caregiverId,
    required this.patientId,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.createdAt,
  });

  CaregiverTaskModel copyWith({
    int? id,
    int? caregiverId,
    int? patientId,
    String? description,
    String? priority,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return CaregiverTaskModel(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'patientId': patientId,
      'description': description,
      'priority': priority,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CaregiverTaskModel.fromMap(Map<String, Object?> map) {
    return CaregiverTaskModel(
      id: map['id'] as int?,
      caregiverId: (map['caregiverId'] as int?) ?? 0,
      patientId: map['patientId'] as int?,
      description: (map['description'] as String?) ?? '',
      priority: (map['priority'] as String?) ?? 'low',
      isDone: ((map['isDone'] as int?) ?? 0) == 1,
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

