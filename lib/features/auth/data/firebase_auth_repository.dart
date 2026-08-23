import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_account.dart';
import 'auth_service.dart';
import 'firebase_auth_error_mapper.dart';
import 'user_profile_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._authService, this._userProfileService);

  final AuthService _authService;
  final UserProfileService _userProfileService;

  @override
  Stream<AppUser?> authStateChanges() {
    return _authService.authStateChanges().map(
      (account) => account == null ? null : _toAppUser(account),
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final account = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(account);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    }
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    var accountCreated = false;
    try {
      final account = await _authService.createAccount(
        email: email.trim(),
        password: password,
      );
      accountCreated = true;
      final trimmedName = name.trim();
      await _authService.updateDisplayName(trimmedName);
      final user = AppUser(
        uid: account.uid,
        name: trimmedName,
        email: account.email,
      );
      await _userProfileService.createProfile(user);
      return user;
    } on FirebaseAuthException catch (error) {
      if (accountCreated) await _rollbackNewAccount();
      throw FirebaseAuthErrorMapper.map(error);
    } on AppException {
      if (accountCreated) await _rollbackNewAccount();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    }
  }

  Future<void> _rollbackNewAccount() async {
    try {
      await _authService.deleteCurrentAccount();
    } on FirebaseAuthException {
      // Preserve the original profile/setup error for the user.
    }
  }

  AppUser _toAppUser(AuthAccount account) {
    final email = account.email.trim();
    final displayName = account.displayName?.trim();
    return AppUser(
      uid: account.uid,
      name: displayName == null || displayName.isEmpty
          ? _nameFromEmail(email)
          : displayName,
      email: email,
    );
  }

  String _nameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'Student' : prefix;
  }
}
