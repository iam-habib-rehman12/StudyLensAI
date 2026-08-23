import '../../../core/persistence/map_reader.dart';

class QuizResult {
  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required List<int> selectedOptionIndexes,
    required this.correctAnswers,
    required this.completedAt,
    required this.xpEarned,
    this.sessionId,
  }) : selectedOptionIndexes = List.unmodifiable(selectedOptionIndexes) {
    if (id.trim().isEmpty || userId.trim().isEmpty || quizId.trim().isEmpty) {
      throw ArgumentError('Quiz result identifiers cannot be empty.');
    }
    if (this.selectedOptionIndexes.isEmpty ||
        this.selectedOptionIndexes.length > 20 ||
        this.selectedOptionIndexes.any((index) => index < 0 || index > 3)) {
      throw ArgumentError(
        'Quiz results require valid selected option indexes.',
      );
    }
    if (correctAnswers < 0 || correctAnswers > totalQuestions || xpEarned < 0) {
      throw ArgumentError('Quiz score values are invalid.');
    }
  }

  final String id;
  final String userId;
  final String quizId;
  final String? sessionId;
  final List<int> selectedOptionIndexes;
  final int correctAnswers;
  final DateTime completedAt;
  final int xpEarned;

  int get totalQuestions => selectedOptionIndexes.length;

  double get accuracy => correctAnswers / totalQuestions;

  factory QuizResult.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    final rawSelections = reader.list('selectedOptionIndexes');
    if (rawSelections.any((selection) => selection is! int)) {
      throw const FormatException('Selected quiz answers must be integers.');
    }
    final selections = rawSelections.cast<int>();
    final declaredTotal = reader.integer(
      'totalQuestions',
      minimum: 1,
      maximum: 20,
    );
    if (declaredTotal != selections.length) {
      throw const FormatException(
        'Quiz result question count is inconsistent.',
      );
    }
    return QuizResult(
      id: reader.string('id'),
      userId: reader.string('userId'),
      quizId: reader.string('quizId'),
      sessionId: reader.nullableString('sessionId'),
      selectedOptionIndexes: selections,
      correctAnswers: reader.integer(
        'correctAnswers',
        minimum: 0,
        maximum: declaredTotal,
      ),
      completedAt: reader.dateTime('completedAt'),
      xpEarned: reader.integer('xpEarned', minimum: 0),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'quizId': quizId,
    'sessionId': sessionId,
    'selectedOptionIndexes': selectedOptionIndexes,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'completedAt': completedAt,
    'xpEarned': xpEarned,
  };
}
