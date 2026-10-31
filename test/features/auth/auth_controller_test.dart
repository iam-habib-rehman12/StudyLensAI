import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/auth/domain/auth_state.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  test('reports unauthenticated after initial auth check', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, AuthStatus.unauthenticated);
    controller.dispose();
    await repository.dispose();
  });

  test('signs in with valid credentials', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);

    final result = await controller.signIn(
      email: 'student@example.com',
      password: 'password123',
    );

    expect(result, isTrue);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.email, 'student@example.com');
    controller.dispose();
    await repository.dispose();
  });

  test('shows a user-safe message for incorrect credentials', () async {
    final repository = FakeAuthRepository(
      onSignIn: (_, _) async => throw const AppException(
        type: AppErrorType.authentication,
        message: 'The email or password is incorrect.',
      ),
    );
    final controller = AuthController(repository);

    final result = await controller.signIn(
      email: 'student@example.com',
      password: 'incorrect',
    );

    expect(result, isFalse);
    expect(
      controller.state.errorMessage,
      'The email or password is incorrect.',
    );
    expect(controller.state.isSubmitting, isFalse);
    controller.dispose();
    await repository.dispose();
  });

  test('registers and signs out a student', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);

    final registered = await controller.register(
      name: 'Ayesha',
      email: 'ayesha@example.com',
      password: 'password123',
    );
    await controller.signOut();

    expect(registered, isTrue);
    expect(repository.registerCalls, 1);
    expect(repository.signOutCalls, 1);
    expect(controller.state.status, AuthStatus.unauthenticated);
    controller.dispose();
    await repository.dispose();
  });

  test('sends password reset and verification emails', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);

    expect(
      await controller.sendPasswordReset('student@example.com'),
      isTrue,
    );
    expect(repository.lastResetEmail, 'student@example.com');
    expect(await controller.resendVerificationEmail(), isTrue);
    expect(repository.verificationCalls, 1);
    expect(controller.state.isSubmitting, isFalse);

    controller.dispose();
    await repository.dispose();
  });

  test('surfaces reset and verification failures', () async {
    final repository = FakeAuthRepository()
      ..passwordResetError = const AppException(
        type: AppErrorType.rateLimited,
        message: 'Too many attempts. Please wait and try again.',
      )
      ..verificationError = const AppException(
        type: AppErrorType.offline,
        message: 'You are offline.',
      );
    final controller = AuthController(repository);

    expect(await controller.sendPasswordReset('student@example.com'), isFalse);
    expect(
      controller.state.errorMessage,
      'Too many attempts. Please wait and try again.',
    );
    expect(await controller.resendVerificationEmail(), isFalse);
    expect(controller.state.errorMessage, 'You are offline.');

    controller.dispose();
    await repository.dispose();
  });

  test('refreshes the authenticated user and verification state', () async {
    final repository = FakeAuthRepository(
      refreshedUser: const AppUser(
        uid: 'uid-1',
        name: 'Student',
        email: 'student@example.com',
        isEmailVerified: true,
      ),
    );
    final controller = AuthController(repository);

    expect(await controller.refreshUser(), isTrue);
    expect(repository.refreshCalls, 1);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.isEmailVerified, isTrue);

    controller.dispose();
    await repository.dispose();
  });

  test('reports refresh failures safely', () async {
    final repository = FakeAuthRepository()
      ..refreshError = const AppException(
        type: AppErrorType.offline,
        message: 'You are offline.',
      );
    final controller = AuthController(repository);

    expect(await controller.refreshUser(), isFalse);
    expect(controller.state.errorMessage, 'You are offline.');

    controller.dispose();
    await repository.dispose();
  });

  test('deletes the account and reports failures safely', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);

    expect(await controller.deleteAccount(password: 'password123'), isTrue);
    expect(repository.deleteCalls, 1);
    expect(repository.lastDeletePassword, 'password123');
    expect(controller.state.status, AuthStatus.unauthenticated);
    controller.dispose();
    await repository.dispose();

    final failingRepository = FakeAuthRepository()
      ..deleteError = const AppException(
        type: AppErrorType.authentication,
        message: 'Sign in again before deleting your account.',
      );
    final failingController = AuthController(failingRepository);

    expect(await failingController.deleteAccount(password: 'wrong'), isFalse);
    expect(
      failingController.state.errorMessage,
      'Sign in again before deleting your account.',
    );
    failingController.dispose();
    await failingRepository.dispose();
  });
}
