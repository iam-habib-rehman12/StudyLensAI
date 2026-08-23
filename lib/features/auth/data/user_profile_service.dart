import '../domain/app_user.dart';

abstract interface class UserProfileService {
  Future<void> createProfile(AppUser user);
}
