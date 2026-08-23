import '../../../core/persistence/map_reader.dart';

class StudentProfile {
  StudentProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.xp = 0,
    this.level = 1,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
  }) {
    if (uid.trim().isEmpty || name.trim().length < 2 || !email.contains('@')) {
      throw ArgumentError('Student identity fields are invalid.');
    }
    if (xp < 0 || level < 1 || totalQuestions < 0 || correctAnswers < 0) {
      throw ArgumentError('Student progress values cannot be negative.');
    }
    if (correctAnswers > totalQuestions) {
      throw ArgumentError('Correct answers cannot exceed total questions.');
    }
  }

  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final int xp;
  final int level;
  final int totalQuestions;
  final int correctAnswers;

  factory StudentProfile.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    return StudentProfile(
      uid: reader.string('uid'),
      name: reader.string('name'),
      email: reader.string('email'),
      createdAt: reader.dateTime('createdAt'),
      xp: reader.integer('xp', minimum: 0),
      level: reader.integer('level', minimum: 1),
      totalQuestions: reader.integer('totalQuestions', minimum: 0),
      correctAnswers: reader.integer('correctAnswers', minimum: 0),
    );
  }

  Map<String, Object?> toMap() => {
    'uid': uid,
    'name': name.trim(),
    'email': email.trim(),
    'createdAt': createdAt,
    'xp': xp,
    'level': level,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
  };
}
