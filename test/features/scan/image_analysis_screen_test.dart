import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/scan/application/image_analysis_controller.dart';
import 'package:studylens_ai/features/scan/presentation/image_analysis_screen.dart';

import '../../helpers/fake_image_analysis_repository.dart';
import '../../helpers/fake_image_intake_service.dart';

void main() {
  testWidgets('offers modes and prompt chips then displays an AI answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageAnalysisScreen(
          controller: ImageAnalysisController(
            'user-1',
            testStudyImage(),
            FakeImageAnalysisRepository(),
          ),
        ),
      ),
    );

    expect(find.text('Simple'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Detailed'), findsOneWidget);
    expect(find.text('Exam'), findsOneWidget);
    expect(find.text('Explain this'), findsOneWidget);

    await tester.tap(find.text('Explain this'));
    await tester.pumpAndSettle();

    expect(find.text('Explain the material in this image.'), findsOneWidget);
    expect(find.textContaining('educational material'), findsOneWidget);
  });
}
