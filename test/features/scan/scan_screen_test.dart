import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/scan/application/scan_controller.dart';
import 'package:studylens_ai/features/scan/domain/image_intake_service.dart';
import 'package:studylens_ai/features/scan/domain/study_image.dart';
import 'package:studylens_ai/features/scan/presentation/scan_screen.dart';

import '../../helpers/fake_image_intake_service.dart';

void main() {
  testWidgets('captures, previews, and discards a local image', (tester) async {
    final service = FakeImageIntakeService()..capturedImage = testStudyImage();
    StudyImage? analyzedImage;

    await tester.pumpWidget(
      MaterialApp(
        home: ScanScreen(
          controller: ScanController(service),
          onAnalyzeImage: (image) => analyzedImage = image,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsOneWidget);
    expect(
      find.textContaining('does not require Cloud Storage'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(find.text('Image preview'), findsOneWidget);
    expect(find.byKey(const Key('scan-image-preview')), findsOneWidget);
    expect(find.text('Retake photo'), findsOneWidget);

    await tester.ensureVisible(find.text('Ask StudyLens'));
    await tester.tap(find.text('Ask StudyLens'));
    expect(analyzedImage, same(service.capturedImage));

    await tester.ensureVisible(find.text('Discard image'));
    await tester.tap(find.text('Discard image'));
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsOneWidget);
  });

  testWidgets('opens settings after camera permission is blocked', (
    tester,
  ) async {
    final service = FakeImageIntakeService()
      ..currentAccess = CameraAccess.permanentlyDenied;

    await tester.pumpWidget(
      MaterialApp(
        home: ScanScreen(
          controller: ScanController(service),
          onAnalyzeImage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Camera access is blocked'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(service.settingsCalls, 1);
  });
}
