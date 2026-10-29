import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/quiz/application/quiz_generation_controller.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/presentation/quiz_generation_screen.dart';

import '../../helpers/fake_quiz_generation_repository.dart';

void main() {
  testWidgets('generates and previews a saved structured quiz', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeQuizGenerationRepository();
    Quiz? startedQuiz;

    await tester.pumpWidget(
      MaterialApp(
        home: QuizGenerationScreen(
          controller: QuizGenerationController('user-1', repository),
          onStartQuiz: (quiz) => startedQuiz = quiz,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('quiz-source-field')),
      'Newton laws of motion and practical examples.',
    );
    await tester.tap(find.byKey(const Key('generate-quiz-button')));
    await tester.pumpAndSettle();

    expect(find.text('Validated and saved'), findsOneWidget);
    expect(find.text('Generated study quiz'), findsOneWidget);
    expect(find.textContaining('5 structured questions'), findsOneWidget);
    expect(repository.saveCalls, 1);

    await tester.ensureVisible(find.byKey(const Key('start-quiz-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-quiz-button')));
    expect(startedQuiz?.id, 'quiz-1');
  });
}
