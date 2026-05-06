class IntakeLogModel {
  static const Object _sentinel = Object();

  final int? id;
  final int medicationId;
  final int userId;
  final String scheduledTime; // HH:mm
  final DateTime? takenAt;
  final String status; // taken|missed|upcoming
  final String date; // yyyy-MM-dd

  const IntakeLogModel({
    this.id,
    required this.medicationId,
    required this.userId,
    required this.scheduledTime,
    required this.takenAt,
    required this.status,
    required this.date,
  });

  IntakeLogModel copyWith({
    int? id,
    int? medicationId,
    int? userId,
    String? scheduledTime,
    Object? takenAt = _sentinel,
    String? status,
    String? date,
  }) {
    return IntakeLogModel(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      userId: userId ?? this.userId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenAt: takenAt == _sentinel ? this.takenAt : takenAt as DateTime?,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'userId': userId,
      'scheduledTime': scheduledTime,
      'takenAt': takenAt?.toIso8601String(),
      'status': status,
      'date': date,
    };
  }

  factory IntakeLogModel.fromMap(Map<String, Object?> map) {
    return IntakeLogModel(
      id: map['id'] as int?,
      medicationId: (map['medicationId'] as int?) ?? 0,
      userId: (map['userId'] as int?) ?? 0,
      scheduledTime: (map['scheduledTime'] as String?) ?? '00:00',
      takenAt: map['takenAt'] == null
          ? null
          : DateTime.tryParse(map['takenAt'] as String),
      status: (map['status'] as String?) ?? 'upcoming',
      date: (map['date'] as String?) ?? '1970-01-01',
    );
  }
}

