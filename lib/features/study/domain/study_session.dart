import '../../../core/persistence/map_reader.dart';

enum StudyMaterialType { text, image, pdf }

enum StudySessionStatus { active, completed }

class StudySession {
  StudySession({
    required this.id,
    required this.userId,
    required this.title,
    required this.materialType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('Session identifiers cannot be empty.');
    }
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw ArgumentError('Session titles must contain 1 to 120 characters.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('Session update time cannot precede creation.');
    }
  }

  final String id;
  final String userId;
  final String title;
  final StudyMaterialType materialType;
  final StudySessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudySession.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    return StudySession(
      id: reader.string('id'),
      userId: reader.string('userId'),
      title: reader.string('title'),
      materialType: _materialType(reader.string('materialType')),
      status: _status(reader.string('status')),
      createdAt: reader.dateTime('createdAt'),
      updatedAt: reader.dateTime('updatedAt'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'title': title.trim(),
    'materialType': materialType.name,
    'status': status.name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static StudyMaterialType _materialType(String value) {
    return StudyMaterialType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw FormatException('Unknown material type "$value".'),
    );
  }

  static StudySessionStatus _status(String value) {
    return StudySessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw FormatException('Unknown session status "$value".'),
    );
  }
}
