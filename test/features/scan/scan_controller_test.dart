import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/scan/application/scan_controller.dart';
import 'package:studylens_ai/features/scan/application/scan_state.dart';
import 'package:studylens_ai/features/scan/domain/image_intake_service.dart';

import '../../helpers/fake_image_intake_service.dart';

void main() {
  test('captures a camera image after permission is granted', () async {
    final service = FakeImageIntakeService()..capturedImage = testStudyImage();
    final controller = ScanController(service);
    addTearDown(controller.dispose);

    await controller.capture();

    expect(controller.state.status, ScanStatus.preview);
    expect(controller.state.image?.name, 'notes.png');
    expect(service.captureCalls, 1);
    expect(service.permissionRequestCalls, 0);
  });

  test(
    'requests permission and explains when camera access is denied',
    () async {
      final service = FakeImageIntakeService()
        ..currentAccess = CameraAccess.denied
        ..requestedAccess = CameraAccess.denied;
      final controller = ScanController(service);
      addTearDown(controller.dispose);

      await controller.capture();

      expect(service.permissionRequestCalls, 1);
      expect(service.captureCalls, 0);
      expect(controller.state.failure, ImageIntakeFailure.permissionDenied);
      expect(controller.state.message, contains('Camera access was denied'));
    },
  );

  test('offers Android settings for permanently denied permission', () async {
    final service = FakeImageIntakeService()
      ..currentAccess = CameraAccess.permanentlyDenied;
    final controller = ScanController(service);
    addTearDown(controller.dispose);

    await controller.capture();
    await controller.openSettings();

    expect(controller.state.requiresSettings, isTrue);
    expect(service.settingsCalls, 1);
    expect(service.captureCalls, 0);
  });

  test('retakes using the original camera source', () async {
    final service = FakeImageIntakeService()
      ..capturedImage = testStudyImage(name: 'first.png');
    final controller = ScanController(service);
    addTearDown(controller.dispose);

    await controller.capture();
    service.capturedImage = testStudyImage(name: 'second.png');
    await controller.retake();

    expect(service.captureCalls, 2);
    expect(controller.state.image?.name, 'second.png');
  });

  test('keeps the preview when a replacement selection is cancelled', () async {
    final service = FakeImageIntakeService()
      ..capturedImage = testStudyImage(name: 'kept.png');
    final controller = ScanController(service);
    addTearDown(controller.dispose);

    await controller.capture();
    service.capturedImage = null;
    await controller.retake();

    expect(controller.state.status, ScanStatus.preview);
    expect(controller.state.image?.name, 'kept.png');
  });
}
