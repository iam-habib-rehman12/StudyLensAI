import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/media_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/image_intake_service.dart';
import '../domain/study_image.dart';

class DeviceImageIntakeService implements ImageIntakeService {
  DeviceImageIntakeService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CameraAccess> cameraAccess() async {
    try {
      return _mapPermission(await Permission.camera.status);
    } catch (error) {
      throw ImageIntakeException(
        failure: ImageIntakeFailure.cameraUnavailable,
        type: AppErrorType.unknown,
        message: 'StudyLens could not check the camera on this device.',
        cause: error,
      );
    }
  }

  @override
  Future<CameraAccess> requestCameraAccess() async {
    try {
      return _mapPermission(await Permission.camera.request());
    } catch (error) {
      throw ImageIntakeException(
        failure: ImageIntakeFailure.permissionDenied,
        type: AppErrorType.permissionDenied,
        message: 'StudyLens could not request camera access.',
        cause: error,
      );
    }
  }

  @override
  Future<StudyImage?> captureImage() => _pick(ImageSource.camera);

  @override
  Future<StudyImage?> selectImage() => _pick(ImageSource.gallery);

  @override
  Future<StudyImage?> recoverLostImage() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.exception case final exception?) {
        throw _pickerException(exception, StudyImageSource.gallery);
      }
      final files = response.files;
      if (files == null || files.isEmpty) return null;
      return _readImage(files.first, StudyImageSource.gallery);
    } on ImageIntakeException {
      rethrow;
    } catch (error) {
      throw ImageIntakeException(
        failure: ImageIntakeFailure.invalidImage,
        type: AppErrorType.unknown,
        message: 'StudyLens could not recover the selected image.',
        cause: error,
      );
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<StudyImage?> _pick(ImageSource source) async {
    final studySource = source == ImageSource.camera
        ? StudyImageSource.camera
        : StudyImageSource.gallery;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: MediaConfig.imageMaxDimension,
        maxHeight: MediaConfig.imageMaxDimension,
        imageQuality: MediaConfig.imageQuality,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return _readImage(file, studySource);
    } on PlatformException catch (error) {
      throw _pickerException(error, studySource);
    } on ImageIntakeException {
      rethrow;
    } catch (error) {
      throw ImageIntakeException(
        failure: studySource == StudyImageSource.camera
            ? ImageIntakeFailure.cameraUnavailable
            : ImageIntakeFailure.galleryUnavailable,
        type: AppErrorType.unknown,
        message: studySource == StudyImageSource.camera
            ? 'StudyLens could not open the camera. Please try again.'
            : 'StudyLens could not open your gallery. Please try again.',
        cause: error,
      );
    }
  }

  Future<StudyImage> _readImage(XFile file, StudyImageSource source) async {
    final length = await file.length();
    if (length <= 0) {
      throw const ImageIntakeException(
        failure: ImageIntakeFailure.invalidImage,
        type: AppErrorType.unknown,
        message: 'That image is empty or unreadable. Choose another image.',
      );
    }
    if (length > MediaConfig.imageMaxBytes) {
      throw const ImageIntakeException(
        failure: ImageIntakeFailure.imageTooLarge,
        type: AppErrorType.unknown,
        message: 'That image is too large. Choose an image under 12 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImageIntakeException(
        failure: ImageIntakeFailure.invalidImage,
        type: AppErrorType.unknown,
        message: 'That image could not be read. Choose another image.',
      );
    }
    return StudyImage(
      name: file.name.trim().isEmpty ? 'study-image' : file.name,
      bytes: bytes,
      source: source,
      mimeType: file.mimeType,
    );
  }

  CameraAccess _mapPermission(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return CameraAccess.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAccess.permanentlyDenied;
    }
    return CameraAccess.denied;
  }

  ImageIntakeException _pickerException(
    PlatformException error,
    StudyImageSource source,
  ) {
    final code = error.code.toLowerCase();
    if (code.contains('permanently') || code.contains('restricted')) {
      return ImageIntakeException(
        failure: ImageIntakeFailure.permanentlyDenied,
        type: AppErrorType.permissionDenied,
        message:
            'Camera access is blocked. Allow it from Android app settings.',
        cause: error,
      );
    }
    if (code.contains('permission') || code.contains('access_denied')) {
      return ImageIntakeException(
        failure: ImageIntakeFailure.permissionDenied,
        type: AppErrorType.permissionDenied,
        message:
            'Camera access was denied. StudyLens needs it to photograph learning material.',
        cause: error,
      );
    }
    final camera = source == StudyImageSource.camera;
    return ImageIntakeException(
      failure: camera
          ? ImageIntakeFailure.cameraUnavailable
          : ImageIntakeFailure.galleryUnavailable,
      type: AppErrorType.unknown,
      message: camera
          ? 'No usable camera is available on this device.'
          : 'No image could be selected from the gallery.',
      cause: error,
    );
  }
}
