import 'auth_account.dart';

abstract interface class AuthService {
  Stream<AuthAccount?> authStateChanges();

  Future<AuthAccount> signIn({required String email, required String password});

  Future<AuthAccount> createAccount({
    required String email,
    required String password,
  });

  Future<void> updateDisplayName(String name);
  Future<void> deleteCurrentAccount();
  Future<void> signOut();
}
