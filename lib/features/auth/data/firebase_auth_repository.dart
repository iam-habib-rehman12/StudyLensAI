import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_data_cleaner.dart';
import 'auth_account.dart';
import 'auth_service.dart';
import 'firebase_auth_error_mapper.dart';
import 'user_profile_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._authService,
    this._userProfileService,
    this._userDataCleaner,
  );

  final AuthService _authService;
  final UserProfileService _userProfileService;
  final UserDataCleaner _userDataCleaner;

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
      try {
        await _authService.sendEmailVerification();
      } catch (_) {
        // Verification is non-blocking and can be resent from Profile.
      }
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
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    }
  }

  @override
  Future<AppUser> refreshUser() async {
    try {
      final account = await _authService.reloadAccount();
      return _toAppUser(account);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final userId = _authService.currentUserId;
    try {
      await _authService.reauthenticateWithPassword(password);
      final currentUserId = _authService.currentUserId ?? userId;
      if (currentUserId != null) {
        await _userDataCleaner.deleteAll(currentUserId);
      }
      await _authService.deleteCurrentAccount();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthErrorMapper.map(error);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
        type: AppErrorType.persistence,
        message:
            'StudyLens could not delete your account data. Please try again.',
        cause: error,
      );
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
      isEmailVerified: account.emailVerified,
    );
  }

  String _nameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'Student' : prefix;
  }
}
