class MedicationModel {
  MedicationModel({
    this.id,
    required this.userId,
    required this.name,
    required this.shape,
    required this.colorHex,
    required this.dosageStrength,
    required this.frequency,
    this.timeOfDay,
    this.voiceReminder = false,
    this.isActive = true,
    this.tags = const <String>[],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const String shapeCapsule = 'capsule';
  static const String shapeRound = 'round';
  static const String shapeSquare = 'square';

  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyCustom = 'custom';

  final int? id;
  final int userId;
  final String name;
  final String shape;
  final String colorHex;
  final String dosageStrength;
  final String frequency;
  final String? timeOfDay;
  final bool voiceReminder;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? shape,
    String? colorHex,
    String? dosageStrength,
    String? frequency,
    String? timeOfDay,
    bool? voiceReminder,
    bool? isActive,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      shape: shape ?? this.shape,
      colorHex: colorHex ?? this.colorHex,
      dosageStrength: dosageStrength ?? this.dosageStrength,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      voiceReminder: voiceReminder ?? this.voiceReminder,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'shape': shape,
      'color_hex': colorHex,
      'dosage_strength': dosageStrength,
      'frequency': frequency,
      'time_of_day': timeOfDay,
      'voice_reminder': voiceReminder ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(Map<String, Object?> map) {
    final tagsRaw = (map['tags'] as String? ?? '').trim();
    return MedicationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      shape: map['shape'] as String,
      colorHex: map['color_hex'] as String,
      dosageStrength: map['dosage_strength'] as String,
      frequency: map['frequency'] as String,
      timeOfDay: map['time_of_day'] as String?,
      voiceReminder: (map['voice_reminder'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      tags: tagsRaw.isEmpty ? const <String>[] : tagsRaw.split(','),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
