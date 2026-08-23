import 'student_profile.dart';

abstract interface class StudentProfileRepository {
  Future<StudentProfile?> getProfile(String userId);
}
