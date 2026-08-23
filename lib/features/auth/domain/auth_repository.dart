import 'app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
