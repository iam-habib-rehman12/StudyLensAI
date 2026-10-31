import 'dart:async';

import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.initialUser,
    this.refreshedUser,
    this.onSignIn,
    this.onRegister,
    this.onSignOut,
  });

  final AppUser? initialUser;
  final AppUser? refreshedUser;
  final Future<AppUser> Function(String email, String password)? onSignIn;
  final Future<AppUser> Function(String name, String email, String password)?
  onRegister;
  final Future<void> Function()? onSignOut;
  final StreamController<AppUser?> _changes = StreamController.broadcast();

  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;
  int passwordResetCalls = 0;
  int verificationCalls = 0;
  int deleteCalls = 0;
  int refreshCalls = 0;
  String? lastResetEmail;
  String? lastDeletePassword;
  Object? passwordResetError;
  Object? verificationError;
  Object? deleteError;
  Object? refreshError;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield initialUser;
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    final user =
        await onSignIn?.call(email, password) ??
        AppUser(uid: 'uid-1', name: 'Student', email: email);
    _changes.add(user);
    return user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls += 1;
    final user =
        await onRegister?.call(name, email, password) ??
        AppUser(uid: 'uid-1', name: name, email: email);
    _changes.add(user);
    return user;
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationCalls += 1;
    if (verificationError case final error?) throw error;
  }

  @override
  Future<AppUser> refreshUser() async {
    refreshCalls += 1;
    if (refreshError case final error?) throw error;
    return refreshedUser ??
        initialUser ??
        const AppUser(
          uid: 'uid-1',
          name: 'Student',
          email: 'student@example.com',
        );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetCalls += 1;
    lastResetEmail = email;
    if (passwordResetError case final error?) throw error;
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    deleteCalls += 1;
    lastDeletePassword = password;
    if (deleteError case final error?) throw error;
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    await onSignOut?.call();
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
