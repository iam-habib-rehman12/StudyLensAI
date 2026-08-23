import 'dart:async';

import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.initialUser,
    this.onSignIn,
    this.onRegister,
    this.onSignOut,
  });

  final AppUser? initialUser;
  final Future<AppUser> Function(String email, String password)? onSignIn;
  final Future<AppUser> Function(String name, String email, String password)?
  onRegister;
  final Future<void> Function()? onSignOut;
  final StreamController<AppUser?> _changes = StreamController.broadcast();

  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;

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
  Future<void> signOut() async {
    signOutCalls += 1;
    await onSignOut?.call();
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
