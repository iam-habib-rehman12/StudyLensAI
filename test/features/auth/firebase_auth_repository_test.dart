import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/data/auth_account.dart';
import 'package:studylens_ai/features/auth/data/auth_service.dart';
import 'package:studylens_ai/features/auth/data/firebase_auth_repository.dart';
import 'package:studylens_ai/features/auth/data/user_profile_service.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/auth/domain/user_data_cleaner.dart';

void main() {
  test('registration creates a profile and sends verification', () async {
    final authService = _FakeAuthService();
    final profileService = _FakeProfileService();
    final repository = FirebaseAuthRepository(
      authService,
      profileService,
      _FakeDataCleaner(),
    );

    final user = await repository.register(
      name: '  Ayesha  ',
      email: 'ayesha@example.com',
      password: 'password123',
    );

    expect(user.name, 'Ayesha');
    expect(user.isEmailVerified, isFalse);
    expect(profileService.createdUser?.uid, 'uid-1');
    expect(authService.updatedDisplayName, 'Ayesha');
    expect(authService.verificationCalls, 1);
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
      final repository = FirebaseAuthRepository(
        authService,
        profileService,
        _FakeDataCleaner(),
      );

      await expectLater(
        repository.register(
          name: 'Ayesha',
          email: 'ayesha@example.com',
          password: 'password123',
        ),
        throwsA(isA<AppException>()),
      );
      expect(authService.deleteCalls, 1);
      expect(authService.verificationCalls, 0);
    },
  );

  test('maps Firebase credential errors to a safe message', () async {
    final authService = _FakeAuthService(
      signInError: FirebaseAuthException(code: 'invalid-credential'),
    );
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
      _FakeDataCleaner(),
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

  test('refreshUser returns the reloaded verification state', () async {
    final authService = _FakeAuthService();
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
      _FakeDataCleaner(),
    );

    final user = await repository.refreshUser();

    expect(user.isEmailVerified, isTrue);
    expect(authService.reloadCalls, 1);
  });

  test('sends password reset to the trimmed email', () async {
    final authService = _FakeAuthService();
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
      _FakeDataCleaner(),
    );

    await repository.sendPasswordResetEmail('  student@example.com  ');

    expect(authService.resetCalls, 1);
    expect(authService.lastResetEmail, 'student@example.com');
  });

  test('reauthenticates, cleans data, then deletes the account', () async {
    final authService = _FakeAuthService();
    final cleaner = _FakeDataCleaner();
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
      cleaner,
    );

    await repository.deleteAccount(password: 'password123');

    expect(authService.reauthCalls, 1);
    expect(authService.lastPassword, 'password123');
    expect(cleaner.deletedUserIds, ['uid-1']);
    expect(authService.deleteCalls, 1);
  });

  test('does not clean data when reauthentication fails', () async {
    final authService = _FakeAuthService(
      reauthError: FirebaseAuthException(code: 'wrong-password'),
    );
    final cleaner = _FakeDataCleaner();
    final repository = FirebaseAuthRepository(
      authService,
      _FakeProfileService(),
      cleaner,
    );

    await expectLater(
      repository.deleteAccount(password: 'wrong-password'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'The email or password is incorrect.',
        ),
      ),
    );
    expect(cleaner.deletedUserIds, isEmpty);
    expect(authService.deleteCalls, 0);
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInError, this.reauthError});

  final FirebaseAuthException? signInError;
  final FirebaseAuthException? reauthError;
  int deleteCalls = 0;
  int verificationCalls = 0;
  int resetCalls = 0;
  int reauthCalls = 0;
  int reloadCalls = 0;
  String? updatedDisplayName;
  String? lastResetEmail;
  String? lastPassword;

  @override
  String? get currentUserId => 'uid-1';

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
  Future<void> reauthenticateWithPassword(String password) async {
    reauthCalls += 1;
    lastPassword = password;
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<AuthAccount> reloadAccount() async {
    reloadCalls += 1;
    return const AuthAccount(
      uid: 'uid-1',
      email: 'student@example.com',
      emailVerified: true,
    );
  }

  @override
  Future<void> sendEmailVerification() async => verificationCalls += 1;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls += 1;
    lastResetEmail = email;
  }

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

class _FakeDataCleaner implements UserDataCleaner {
  final List<String> deletedUserIds = [];

  @override
  Future<void> deleteAll(String userId) async {
    deletedUserIds.add(userId);
  }
}
