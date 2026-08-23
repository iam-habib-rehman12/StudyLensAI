import '../domain/image_intake_service.dart';
import '../domain/study_image.dart';

enum ScanStatus { ready, recovering, requestingPermission, selecting, preview }

class ScanState {
  const ScanState({
    this.status = ScanStatus.ready,
    this.image,
    this.failure,
    this.message,
  });

  final ScanStatus status;
  final StudyImage? image;
  final ImageIntakeFailure? failure;
  final String? message;

  bool get isBusy => switch (status) {
    ScanStatus.recovering ||
    ScanStatus.requestingPermission ||
    ScanStatus.selecting => true,
    ScanStatus.ready || ScanStatus.preview => false,
  };

  bool get requiresSettings => failure == ImageIntakeFailure.permanentlyDenied;

  ScanState copyWith({
    ScanStatus? status,
    StudyImage? image,
    bool clearImage = false,
    ImageIntakeFailure? failure,
    String? message,
    bool clearIssue = false,
  }) {
    return ScanState(
      status: status ?? this.status,
      image: clearImage ? null : image ?? this.image,
      failure: clearIssue ? null : failure ?? this.failure,
      message: clearIssue ? null : message ?? this.message,
    );
  }
}
