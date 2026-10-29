import '../../../core/persistence/map_reader.dart';

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.question,
    required List<String> options,
    required this.correctOptionIndex,
    required this.explanation,
  }) : options = List.unmodifiable(options) {
    if (id.trim().isEmpty ||
        question.trim().isEmpty ||
        question.trim().length > 500) {
      throw ArgumentError(
        'Quiz question identifiers and text cannot be empty.',
      );
    }
    if (this.options.length != 4 ||
        this.options.any(
          (option) => option.trim().isEmpty || option.trim().length > 300,
        ) ||
        this.options
                .map((option) => option.trim().toLowerCase())
                .toSet()
                .length !=
            4) {
      throw ArgumentError('Every quiz question requires four unique options.');
    }
    if (correctOptionIndex < 0 || correctOptionIndex >= this.options.length) {
      throw ArgumentError(
        'The correct option index is outside the option list.',
      );
    }
    if (explanation.trim().isEmpty || explanation.trim().length > 2000) {
      throw ArgumentError('Every quiz question requires an explanation.');
    }
  }

  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  factory QuizQuestion.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    final rawOptions = reader.list('options');
    if (rawOptions.any((option) => option is! String)) {
      throw const FormatException('Quiz options must all be strings.');
    }
    return QuizQuestion(
      id: reader.string('id'),
      question: reader.string('question'),
      options: rawOptions.cast<String>(),
      correctOptionIndex: reader.integer(
        'correctOptionIndex',
        minimum: 0,
        maximum: 3,
      ),
      explanation: reader.string('explanation'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'question': question.trim(),
    'options': options.map((option) => option.trim()).toList(growable: false),
    'correctOptionIndex': correctOptionIndex,
    'explanation': explanation.trim(),
  };
}

class Quiz {
  Quiz({
    required this.id,
    required this.userId,
    required this.title,
    required List<QuizQuestion> questions,
    required this.createdAt,
    this.sessionId,
  }) : questions = List.unmodifiable(questions) {
    if (id.trim().isEmpty ||
        userId.trim().isEmpty ||
        title.trim().isEmpty ||
        title.trim().length > 120) {
      throw ArgumentError('Quiz identifiers and title cannot be empty.');
    }
    if (this.questions.isEmpty || this.questions.length > 20) {
      throw ArgumentError('A quiz must contain 1 to 20 questions.');
    }
    final questionIds = this.questions.map((question) => question.id).toSet();
    final questionText = this.questions
        .map((question) => question.question.trim().toLowerCase())
        .toSet();
    if (questionIds.length != this.questions.length ||
        questionText.length != this.questions.length) {
      throw ArgumentError('Quiz questions cannot contain duplicates.');
    }
  }

  final String id;
  final String userId;
  final String? sessionId;
  final String title;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  factory Quiz.fromMap(Map<String, Object?> data) {
    final reader = MapReader(data);
    final rawQuestions = reader.list('questions');
    final questions = rawQuestions
        .map((question) {
          if (question is! Map) {
            throw const FormatException('Quiz questions must be objects.');
          }
          return QuizQuestion.fromMap(question.cast<String, Object?>());
        })
        .toList(growable: false);

    final declaredCount = reader.integer(
      'questionCount',
      minimum: 1,
      maximum: 20,
    );
    if (declaredCount != questions.length) {
      throw const FormatException('Quiz question count is inconsistent.');
    }
    return Quiz(
      id: reader.string('id'),
      userId: reader.string('userId'),
      sessionId: reader.nullableString('sessionId'),
      title: reader.string('title'),
      questions: questions,
      createdAt: reader.dateTime('createdAt'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'sessionId': sessionId,
    'title': title.trim(),
    'questionCount': questions.length,
    'questions': questions
        .map((question) => question.toMap())
        .toList(growable: false),
    'createdAt': createdAt,
  };
}
