import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/data/auth_account.dart';
import 'package:studylens_ai/features/auth/data/auth_service.dart';
import 'package:studylens_ai/features/auth/data/firebase_auth_repository.dart';
import 'package:studylens_ai/features/auth/data/user_profile_service.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';

void main() {
  test('registration creates a matching user profile', () async {
    final authService = _FakeAuthService();
    final profileService = _FakeProfileService();
    final repository = FirebaseAuthRepository(authService, profileService);

    final user = await repository.register(
      name: '  Ayesha  ',
      email: 'ayesha@example.com',
      password: 'password123',
    );

    expect(user.name, 'Ayesha');
    expect(profileService.createdUser?.uid, 'uid-1');
    expect(authService.updatedDisplayName, 'Ayesha');
    expect(authService.deleteCalls, 0);
  });

  test(
    'registration rolls back a new account if profile creation fails',
    () async {
      final authService = _FakeAuthService();
      final profileService = _FakeProfileService(
        error: const AppException(
          type: AppErrorType.persistence,
          message: 'Profile could not be saved.',
        ),
      );
      final repository = FirebaseAuthRepository(authService, profileService);

      await expectLater(
        repository.register(
          name: 'Ayesha',
          email: 'ayesha@example.com',
          password: 'password123',
        ),
        throwsA(isA<AppException>()),
      );
      expect(authService.deleteCalls, 1);
    },
  );

  test('maps Firebase credential errors to a safe message', () async {
    final authService = _FakeAuthService(
      signInError: FirebaseAuthException(code: 'invalid-credential'),
    );
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
    );

    await expectLater(
      repository.signIn(email: 'student@example.com', password: 'wrong-pass'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'The email or password is incorrect.',
        ),
      ),
    );
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInError});

  final FirebaseAuthException? signInError;
  int deleteCalls = 0;
  String? updatedDisplayName;

  @override
  Stream<AuthAccount?> authStateChanges() => const Stream.empty();

  @override
  Future<AuthAccount> createAccount({
    required String email,
    required String password,
  }) async {
    return AuthAccount(uid: 'uid-1', email: email);
  }

  @override
  Future<void> deleteCurrentAccount() async => deleteCalls += 1;

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return AuthAccount(uid: 'uid-1', email: email);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateDisplayName(String name) async {
    updatedDisplayName = name;
  }
}

class _FakeProfileService implements UserProfileService {
  _FakeProfileService({this.error});

  final AppException? error;
  AppUser? createdUser;

  @override
  Future<void> createProfile(AppUser user) async {
    if (error != null) throw error!;
    createdUser = user;
  }
}
