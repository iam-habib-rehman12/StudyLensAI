import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/config/media_config.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/document/domain/study_document.dart';

void main() {
  test('accepts a complete PDF signature and end marker', () {
    final document = StudyDocument(
      name: 'lecture.PDF',
      bytes: Uint8List.fromList('%PDF-1.7\ncontent\n%%EOF'.codeUnits),
    );

    expect(document.byteLength, greaterThan(0));
  });

  for (final invalid in <({String name, List<int> bytes, String message})>[
    (
      name: 'lecture.txt',
      bytes: '%PDF-1.7\n%%EOF'.codeUnits,
      message: 'PDF documents only',
    ),
    (name: 'lecture.pdf', bytes: const [], message: 'empty or unreadable'),
    (
      name: 'lecture.pdf',
      bytes: 'not a pdf\n%%EOF'.codeUnits,
      message: 'not a valid PDF',
    ),
    (
      name: 'lecture.pdf',
      bytes: '%PDF-1.7\nbroken'.codeUnits,
      message: 'incomplete or damaged',
    ),
  ]) {
    test('rejects invalid PDF: ${invalid.message}', () {
      expect(
        () => StudyDocument(
          name: invalid.name,
          bytes: Uint8List.fromList(invalid.bytes),
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            contains(invalid.message),
          ),
        ),
      );
    });
  }

  test('rejects PDFs above the safe inline request limit', () {
    final bytes = Uint8List(MediaConfig.pdfMaxBytes + 1)
      ..setRange(0, 5, '%PDF-'.codeUnits)
      ..setRange(
        MediaConfig.pdfMaxBytes - 4,
        MediaConfig.pdfMaxBytes + 1,
        '%%EOF'.codeUnits,
      );

    expect(
      () => StudyDocument(name: 'large.pdf', bytes: bytes),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('under 14 MB'),
        ),
      ),
    );
  });
}
