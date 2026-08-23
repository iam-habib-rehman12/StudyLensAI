import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
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
}
