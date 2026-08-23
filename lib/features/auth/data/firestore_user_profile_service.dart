import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/student_profile.dart';
import 'user_profile_service.dart';

class FirestoreUserProfileService implements UserProfileService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<void> createProfile(AppUser user) async {
    try {
      final profile = StudentProfile(
        uid: user.uid,
        name: user.name,
        email: user.email,
        createdAt: DateTime.now(),
      );
      final data = profile.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set(data);
    } on FirebaseException catch (error) {
      throw AppException(
        type: error.code == 'permission-denied'
            ? AppErrorType.permissionDenied
            : AppErrorType.persistence,
        message:
            'StudyLens could not finish setting up your profile. Try again.',
        cause: error,
      );
    }
  }
}
