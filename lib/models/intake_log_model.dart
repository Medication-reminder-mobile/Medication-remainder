class IntakeLogModel {
  IntakeLogModel({
    this.id,
    required this.userId,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.notes,
  });

  static const String statusTaken = 'taken';
  static const String statusMissed = 'missed';
  static const String statusUpcoming = 'upcoming';

  final int? id;
  final int userId;
  final int medicationId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status;
  final String? notes;

  IntakeLogModel copyWith({
    int? id,
    int? userId,
    int? medicationId,
    DateTime? scheduledAt,
    DateTime? takenAt,
    String? status,
    String? notes,
  }) {
    return IntakeLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'medication_id': medicationId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'taken_at': takenAt?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory IntakeLogModel.fromMap(Map<String, Object?> map) {
    return IntakeLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      medicationId: map['medication_id'] as int,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      takenAt: map['taken_at'] == null
          ? null
          : DateTime.parse(map['taken_at'] as String),
      status: map['status'] as String,
      notes: map['notes'] as String?,
    );
  }
}
