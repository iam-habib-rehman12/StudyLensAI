import 'dart:convert';
import 'dart:typed_data';

import 'package:studylens_ai/features/scan/domain/image_intake_service.dart';
import 'package:studylens_ai/features/scan/domain/study_image.dart';

class FakeImageIntakeService implements ImageIntakeService {
  CameraAccess currentAccess = CameraAccess.granted;
  CameraAccess requestedAccess = CameraAccess.granted;
  StudyImage? capturedImage;
  StudyImage? galleryImage;
  StudyImage? recoveredImage;
  Object? cameraAccessError;
  Object? captureError;
  Object? galleryError;
  bool settingsOpened = true;

  int permissionRequestCalls = 0;
  int captureCalls = 0;
  int galleryCalls = 0;
  int settingsCalls = 0;

  @override
  Future<CameraAccess> cameraAccess() async {
    if (cameraAccessError case final error?) throw error;
    return currentAccess;
  }

  @override
  Future<StudyImage?> captureImage() async {
    captureCalls += 1;
    if (captureError case final error?) throw error;
    return capturedImage;
  }

  @override
  Future<bool> openSettings() async {
    settingsCalls += 1;
    return settingsOpened;
  }

  @override
  Future<StudyImage?> recoverLostImage() async => recoveredImage;

  @override
  Future<CameraAccess> requestCameraAccess() async {
    permissionRequestCalls += 1;
    return requestedAccess;
  }

  @override
  Future<StudyImage?> selectImage() async {
    galleryCalls += 1;
    if (galleryError case final error?) throw error;
    return galleryImage;
  }
}

StudyImage testStudyImage({
  StudyImageSource source = StudyImageSource.camera,
  String name = 'notes.png',
}) {
  return StudyImage(
    name: name,
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
    source: source,
    mimeType: 'image/png',
  );
}
