import 'app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<AppUser> refreshUser();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteAccount({required String password});

  Future<void> signOut();
}
