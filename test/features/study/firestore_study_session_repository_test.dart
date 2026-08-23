import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/core/persistence/document_database.dart';
import 'package:studylens_ai/core/persistence/firestore_paths.dart';
import 'package:studylens_ai/features/study/data/firestore_study_session_repository.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';

import '../../helpers/fake_document_database.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 21, 10);

  test('creates a user-scoped session with server timestamps', () async {
    final database = FakeDocumentDatabase();
    final repository = FirestoreStudySessionRepository(database);
    final session = StudySession(
      id: 'session-1',
      userId: 'user-1',
      title: 'Cell biology',
      materialType: StudyMaterialType.pdf,
      status: StudySessionStatus.active,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await repository.createSession(session);

    final write = database.writes.single;
    expect(write.path, FirestorePaths.session('user-1', 'session-1'));
    expect(write.merge, isFalse);
    expect(write.data['createdAt'], same(serverTimestamp));
    expect(write.data['updatedAt'], same(serverTimestamp));
  });

  test('completes a session without replacing its stored content', () async {
    final database = FakeDocumentDatabase();
    final repository = FirestoreStudySessionRepository(database);

    await repository.completeSession(userId: 'user-1', sessionId: 'session-1');

    final write = database.writes.single;
    expect(write.merge, isTrue);
    expect(write.data['status'], 'completed');
    expect(write.data['updatedAt'], same(serverTimestamp));
  });

  test(
    'rejects a stored session whose owner does not match its path',
    () async {
      final database = FakeDocumentDatabase();
      database.documents[FirestorePaths.session('user-1', 'session-1')] = {
        'id': 'session-1',
        'userId': 'user-2',
        'title': 'Unsafe data',
        'materialType': 'text',
        'status': 'active',
        'createdAt': createdAt,
        'updatedAt': createdAt,
      };
      final repository = FirestoreStudySessionRepository(database);

      await expectLater(
        repository.getSession(userId: 'user-1', sessionId: 'session-1'),
        throwsA(
          isA<AppException>().having(
            (error) => error.type,
            'type',
            AppErrorType.invalidDocument,
          ),
        ),
      );
    },
  );
}
