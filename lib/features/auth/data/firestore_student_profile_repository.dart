import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/student_profile.dart';
import '../domain/student_profile_repository.dart';

class FirestoreStudentProfileRepository implements StudentProfileRepository {
  const FirestoreStudentProfileRepository(this._database);

  final DocumentDatabase _database;

  @override
  Future<StudentProfile?> getProfile(String userId) async {
    final data = await _database.getDocument(FirestorePaths.user(userId));
    if (data == null) return null;
    try {
      final profile = StudentProfile.fromMap(data);
      if (profile.uid != userId) {
        throw const FormatException('Profile ownership data is inconsistent.');
      }
      return profile;
    } on FormatException catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message:
            'Your saved student profile is malformed and cannot be loaded.',
        cause: error,
      );
    } on ArgumentError catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message:
            'Your saved student profile is malformed and cannot be loaded.',
        cause: error,
      );
    }
  }
}
