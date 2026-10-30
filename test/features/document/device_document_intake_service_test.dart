import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/document/data/device_document_intake_service.dart';
import 'package:studylens_ai/features/document/domain/document_intake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('times out when the platform picker never answers', () async {
    const channel = MethodChannel('studylens/test_picker');
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => pending.future);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = DeviceDocumentIntakeService(
      channel: channel,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      service.selectPdf(),
      throwsA(
        isA<DocumentIntakeException>()
            .having(
              (error) => error.message,
              'message',
              contains('took too long'),
            )
            .having(
              (error) => error.failure,
              'failure',
              DocumentIntakeFailure.unavailable,
            ),
      ),
    );
  });
}
