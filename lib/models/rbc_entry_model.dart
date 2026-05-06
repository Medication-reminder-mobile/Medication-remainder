class RbcEntryModel {
  final int? id;
  final int userId;

  /// RBC count in millions per µL (e.g. 4.7)
  final double rbcCount;

  /// Hemoglobin in g/dL (e.g. 13.5)
  final double hemoglobin;

  /// Hematocrit in % (e.g. 41.0)
  final double hematocrit;

  /// Mean Corpuscular Volume in fL (e.g. 90.0)
  final double mcv;

  /// Optional note from doctor or patient
  final String? note;

  final DateTime recordedAt;

  const RbcEntryModel({
    this.id,
    required this.userId,
    required this.rbcCount,
    required this.hemoglobin,
    required this.hematocrit,
    required this.mcv,
    this.note,
    required this.recordedAt,
  });

  RbcEntryModel copyWith({
    int? id,
    int? userId,
    double? rbcCount,
    double? hemoglobin,
    double? hematocrit,
    double? mcv,
    String? note,
    DateTime? recordedAt,
  }) {
    return RbcEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rbcCount: rbcCount ?? this.rbcCount,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      hematocrit: hematocrit ?? this.hematocrit,
      mcv: mcv ?? this.mcv,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'userId': userId,
      'rbcCount': rbcCount,
      'hemoglobin': hemoglobin,
      'hematocrit': hematocrit,
      'mcv': mcv,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory RbcEntryModel.fromMap(Map<String, Object?> map) {
    return RbcEntryModel(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      rbcCount: (map['rbcCount'] as num?)?.toDouble() ?? 0.0,
      hemoglobin: (map['hemoglobin'] as num?)?.toDouble() ?? 0.0,
      hematocrit: (map['hematocrit'] as num?)?.toDouble() ?? 0.0,
      mcv: (map['mcv'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String?,
      recordedAt:
          DateTime.tryParse((map['recordedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Normal reference ranges for RBC markers.
class RbcRanges {
  // RBC count (million/µL)
  static const double rbcMaleMin = 4.5;
  static const double rbcMaleMax = 5.9;
  static const double rbcFemaleMin = 4.1;
  static const double rbcFemaleMax = 5.1;
  // Use a general range for display
  static const double rbcMin = 4.1;
  static const double rbcMax = 5.9;

  // Hemoglobin (g/dL)
  static const double hgbMin = 12.0;
  static const double hgbMax = 17.5;

  // Hematocrit (%)
  static const double hctMin = 36.0;
  static const double hctMax = 52.0;

  // MCV (fL)
  static const double mcvMin = 80.0;
  static const double mcvMax = 100.0;

  static RbcStatus statusFor(double value, double min, double max) {
    if (value < min) return RbcStatus.low;
    if (value > max) return RbcStatus.high;
    return RbcStatus.normal;
  }
}

enum RbcStatus { low, normal, high }
