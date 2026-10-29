import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result_repository.dart';

class FakeQuizResultRepository implements QuizResultRepository {
  FakeQuizResultRepository({this.results = const [], this.error, this.stream});

  final List<QuizResult> saved = [];
  List<QuizResult> results;
  Object? error;
  Stream<List<QuizResult>>? stream;
  int saveCalls = 0;
  int watchCalls = 0;
  Object? saveError;

  @override
  Future<void> saveResult(QuizResult result) async {
    saveCalls += 1;
    if (saveError case final error?) throw error;
    saved.add(result);
  }

  @override
  Stream<List<QuizResult>> watchRecentResults(
    String userId, {
    int limit = 20,
  }) {
    watchCalls += 1;
    if (stream case final value?) return value;
    if (error case final value?) return Stream.error(value);
    return Stream.value(results);
  }
}
