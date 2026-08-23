import '../../../core/errors/app_exception.dart';
import 'study_image.dart';

enum CameraAccess { granted, denied, permanentlyDenied, unavailable }

enum ImageIntakeFailure {
  permissionDenied,
  permanentlyDenied,
  cameraUnavailable,
  galleryUnavailable,
  invalidImage,
  imageTooLarge,
  unknown,
}

class ImageIntakeException extends AppException {
  const ImageIntakeException({
    required this.failure,
    required super.type,
    required super.message,
    super.cause,
  });

  final ImageIntakeFailure failure;
}

abstract interface class ImageIntakeService {
  Future<CameraAccess> cameraAccess();

  Future<CameraAccess> requestCameraAccess();

  Future<StudyImage?> captureImage();

  Future<StudyImage?> selectImage();

  Future<StudyImage?> recoverLostImage();

  Future<bool> openSettings();
}
