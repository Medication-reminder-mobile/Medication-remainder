class CaregiverLinkModel {
  final int? id;
  final int caregiverId;
  final int patientId;
  final bool editPermission;
  final DateTime linkedAt;

  const CaregiverLinkModel({
    this.id,
    required this.caregiverId,
    required this.patientId,
    required this.editPermission,
    required this.linkedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'patientId': patientId,
      'editPermission': editPermission ? 1 : 0,
      'linkedAt': linkedAt.toIso8601String(),
    };
  }

  factory CaregiverLinkModel.fromMap(Map<String, Object?> map) {
    return CaregiverLinkModel(
      id: map['id'] as int?,
      caregiverId: (map['caregiverId'] as int?) ?? 0,
      patientId: (map['patientId'] as int?) ?? 0,
      editPermission: ((map['editPermission'] as int?) ?? 0) == 1,
      linkedAt: DateTime.tryParse((map['linkedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

