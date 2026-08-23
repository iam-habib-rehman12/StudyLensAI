import 'package:flutter/foundation.dart';

import '../domain/image_intake_service.dart';
import '../domain/study_image.dart';
import 'scan_state.dart';

class ScanController extends ChangeNotifier {
  ScanController(this._service);

  final ImageIntakeService _service;
  ScanState _state = const ScanState();
  bool _initialized = false;
  bool _disposed = false;
  int _operation = 0;

  ScanState get state => _state;

  Future<void> initialize() async {
    if (_initialized || _state.isBusy) return;
    _initialized = true;
    final operation = ++_operation;
    _setState(_state.copyWith(status: ScanStatus.recovering, clearIssue: true));
    try {
      final recovered = await _service.recoverLostImage();
      if (!_isCurrent(operation)) return;
      _finishSelection(recovered);
    } on ImageIntakeException catch (error) {
      if (_isCurrent(operation)) _showError(error);
    } catch (_) {
      if (_isCurrent(operation)) {
        _showUnknown('StudyLens could not restore the previous image.');
      }
    }
  }

  Future<void> capture() async {
    if (_state.isBusy) return;
    final operation = ++_operation;
    _setState(
      _state.copyWith(
        status: ScanStatus.requestingPermission,
        clearIssue: true,
      ),
    );
    try {
      var access = await _service.cameraAccess();
      if (!_isCurrent(operation)) return;
      if (access == CameraAccess.denied) {
        access = await _service.requestCameraAccess();
        if (!_isCurrent(operation)) return;
      }
      if (access != CameraAccess.granted) {
        _showCameraAccess(access);
        return;
      }
      _setState(_state.copyWith(status: ScanStatus.selecting));
      final image = await _service.captureImage();
      if (_isCurrent(operation)) _finishSelection(image);
    } on ImageIntakeException catch (error) {
      if (_isCurrent(operation)) _showError(error);
    } catch (_) {
      if (_isCurrent(operation)) {
        _showUnknown('StudyLens could not open the camera. Please try again.');
      }
    }
  }

  Future<void> selectFromGallery() => _selectFromGallery();

  Future<void> retake() async {
    if (_state.image?.source == StudyImageSource.camera) {
      await capture();
    } else {
      await _selectFromGallery();
    }
  }

  Future<void> _selectFromGallery() async {
    if (_state.isBusy) return;
    final operation = ++_operation;
    _setState(_state.copyWith(status: ScanStatus.selecting, clearIssue: true));
    try {
      final image = await _service.selectImage();
      if (_isCurrent(operation)) _finishSelection(image);
    } on ImageIntakeException catch (error) {
      if (_isCurrent(operation)) _showError(error);
    } catch (_) {
      if (_isCurrent(operation)) {
        _showUnknown(
          'StudyLens could not open your gallery. Please try again.',
        );
      }
    }
  }

  Future<void> openSettings() async {
    if (_state.isBusy) return;
    try {
      final opened = await _service.openSettings();
      if (!opened) {
        _showUnknown('Android app settings could not be opened.');
      }
    } catch (_) {
      _showUnknown('Android app settings could not be opened.');
    }
  }

  void discard() {
    if (_state.isBusy) return;
    _setState(const ScanState());
  }

  void clearIssue() {
    if (_state.isBusy || _state.message == null) return;
    _setState(_state.copyWith(clearIssue: true));
  }

  void _finishSelection(StudyImage? image) {
    if (image == null) {
      _setState(
        _state.copyWith(
          status: _state.image == null ? ScanStatus.ready : ScanStatus.preview,
          clearIssue: true,
        ),
      );
      return;
    }
    _setState(
      _state.copyWith(
        status: ScanStatus.preview,
        image: image,
        clearIssue: true,
      ),
    );
  }

  void _showCameraAccess(CameraAccess access) {
    switch (access) {
      case CameraAccess.granted:
        return;
      case CameraAccess.denied:
        _setState(
          _state.copyWith(
            status: _state.image == null
                ? ScanStatus.ready
                : ScanStatus.preview,
            failure: ImageIntakeFailure.permissionDenied,
            message:
                'Camera access was denied. Allow access to photograph your learning material.',
          ),
        );
      case CameraAccess.permanentlyDenied:
        _setState(
          _state.copyWith(
            status: _state.image == null
                ? ScanStatus.ready
                : ScanStatus.preview,
            failure: ImageIntakeFailure.permanentlyDenied,
            message:
                'Camera access is blocked. Open Android settings and allow Camera for StudyLens AI.',
          ),
        );
      case CameraAccess.unavailable:
        _setState(
          _state.copyWith(
            status: _state.image == null
                ? ScanStatus.ready
                : ScanStatus.preview,
            failure: ImageIntakeFailure.cameraUnavailable,
            message:
                'No usable camera is available. You can still choose an image from the gallery.',
          ),
        );
    }
  }

  void _showError(ImageIntakeException error) {
    _setState(
      _state.copyWith(
        status: _state.image == null ? ScanStatus.ready : ScanStatus.preview,
        failure: error.failure,
        message: error.message,
      ),
    );
  }

  void _showUnknown(String message) {
    _setState(
      _state.copyWith(
        status: _state.image == null ? ScanStatus.ready : ScanStatus.preview,
        failure: ImageIntakeFailure.unknown,
        message: message,
      ),
    );
  }

  bool _isCurrent(int operation) => !_disposed && operation == _operation;

  void _setState(ScanState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operation += 1;
    super.dispose();
  }
}
