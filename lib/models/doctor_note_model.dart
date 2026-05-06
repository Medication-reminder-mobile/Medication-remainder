class DoctorNoteModel {
  final int? id;
  final int patientId;
  final String note;
  final DateTime createdAt;

  const DoctorNoteModel({
    this.id,
    required this.patientId,
    required this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DoctorNoteModel.fromMap(Map<String, Object?> map) {
    return DoctorNoteModel(
      id: map['id'] as int?,
      patientId: (map['patientId'] as int?) ?? 0,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

