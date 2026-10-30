import 'dart:typed_data';

import '../../../core/config/media_config.dart';
import '../../../core/errors/app_exception.dart';

class StudyDocument {
  StudyDocument({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes) {
    _validate();
  }

  final String name;
  final Uint8List bytes;

  int get byteLength => bytes.lengthInBytes;

  void _validate() {
    final normalizedName = name.trim().toLowerCase();
    if (!normalizedName.endsWith('.pdf')) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'StudyLens supports PDF documents only.',
      );
    }
    if (bytes.isEmpty) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'That PDF is empty or unreadable. Choose another document.',
      );
    }
    if (byteLength > MediaConfig.pdfMaxBytes) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'That PDF is too large. Choose a document under 10 MB.',
      );
    }

    final headerLength = byteLength < 1024 ? byteLength : 1024;
    final header = String.fromCharCodes(bytes.sublist(0, headerLength));
    if (!header.contains('%PDF-')) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'That file is not a valid PDF. Choose another document.',
      );
    }

    final tailStart = byteLength > 2048 ? byteLength - 2048 : 0;
    final tail = String.fromCharCodes(bytes.sublist(tailStart));
    if (!tail.contains('%%EOF')) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'That PDF appears incomplete or damaged.',
      );
    }
  }
}
