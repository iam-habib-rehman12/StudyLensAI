import '../../../core/persistence/map_reader.dart';

enum StudyMessageRole { student, assistant }

class StudyMessage {
  StudyMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  }) {
    if (id.trim().isEmpty ||
        userId.trim().isEmpty ||
        sessionId.trim().isEmpty) {
      throw ArgumentError('Message identifiers cannot be empty.');
    }
    if (content.trim().isEmpty || content.length > 12000) {
      throw ArgumentError(
        'Message content must contain 1 to 12000 characters.',
      );
    }
  }

  final String id;
  final String userId;
  final String sessionId;
  final StudyMessageRole role;
  final String content;
  final DateTime createdAt;

  factory StudyMessage.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    final roleName = reader.string('role');
    final role = StudyMessageRole.values.firstWhere(
      (value) => value.name == roleName,
      orElse: () => throw FormatException('Unknown message role "$roleName".'),
    );
    return StudyMessage(
      id: reader.string('id'),
      userId: reader.string('userId'),
      sessionId: reader.string('sessionId'),
      role: role,
      content: reader.string('content'),
      createdAt: reader.dateTime('createdAt'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'sessionId': sessionId,
    'role': role.name,
    'content': content.trim(),
    'createdAt': createdAt,
  };
}
