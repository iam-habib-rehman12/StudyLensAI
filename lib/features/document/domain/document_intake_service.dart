import '../../../core/errors/app_exception.dart';
import 'study_document.dart';

enum DocumentIntakeFailure {
  unsupported,
  empty,
  tooLarge,
  malformed,
  unavailable,
}

class DocumentIntakeException extends AppException {
  const DocumentIntakeException({
    required this.failure,
    required super.type,
    required super.message,
    super.cause,
  });

  final DocumentIntakeFailure failure;
}

abstract interface class DocumentIntakeService {
  Future<StudyDocument?> selectPdf();
}
