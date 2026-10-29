import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/document_intake_service.dart';
import '../domain/study_document.dart';

class DeviceDocumentIntakeService implements DocumentIntakeService {
  DeviceDocumentIntakeService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('studylens/document_picker');

  final MethodChannel _channel;

  @override
  Future<StudyDocument?> selectPdf() async {
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'selectPdf',
      );
      if (response == null) return null;
      final name = response['name'];
      final bytes = response['bytes'];
      if (name is! String || bytes is! Uint8List) {
        throw const DocumentIntakeException(
          failure: DocumentIntakeFailure.malformed,
          type: AppErrorType.invalidDocument,
          message: 'The selected PDF could not be read safely.',
        );
      }
      return StudyDocument(name: name, bytes: bytes);
    } on AppException {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'too_large') {
        throw DocumentIntakeException(
          failure: DocumentIntakeFailure.tooLarge,
          type: AppErrorType.invalidDocument,
          message: 'That PDF is too large. Choose a document under 14 MB.',
          cause: error,
        );
      }
      throw DocumentIntakeException(
        failure: DocumentIntakeFailure.unavailable,
        type: AppErrorType.unknown,
        message: 'StudyLens could not read that PDF. Choose it again.',
        cause: error,
      );
    } catch (error) {
      throw DocumentIntakeException(
        failure: DocumentIntakeFailure.unavailable,
        type: AppErrorType.unknown,
        message: 'StudyLens could not read that PDF. Choose it again.',
        cause: error,
      );
    }
  }
}
