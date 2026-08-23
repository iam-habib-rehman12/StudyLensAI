import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/tutor/application/tutor_controller.dart';
import 'package:studylens_ai/features/tutor/presentation/tutor_screen.dart';

import '../../helpers/fake_tutor_repository.dart';

void main() {
  testWidgets('asks a question and presents the completed tutor answer', (
    tester,
  ) async {
    final repository = FakeTutorRepository();
    final controller = TutorController('user-1', repository);

    await tester.pumpWidget(
      MaterialApp(home: TutorScreen(controller: controller)),
    );

    expect(find.text('What would you like to understand?'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Explain cellular respiration',
    );
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();

    expect(find.text('Explain cellular respiration'), findsOneWidget);
    expect(
      find.text('A clear answer about Explain cellular respiration'),
      findsOneWidget,
    );
    expect(repository.savedMessages, hasLength(2));
  });
}
