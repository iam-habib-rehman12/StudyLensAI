import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/profile/presentation/profile_screen.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  const user = AppUser(
    uid: 'uid-1',
    name: 'Habib',
    email: 'habib@example.com',
  );

  testWidgets('resends a verification email for an unverified account', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(user: user, authController: controller),
        ),
      ),
    );

    expect(find.text('Email not verified'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resend-verification')));
    await tester.pumpAndSettle();

    expect(repository.verificationCalls, 1);
    expect(
      find.text('Verification email sent. Check your inbox.'),
      findsOneWidget,
    );
  });

  testWidgets('refreshes the verification status from the profile', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      refreshedUser: const AppUser(
        uid: 'uid-1',
        name: 'Habib',
        email: 'habib@example.com',
        isEmailVerified: true,
      ),
    );
    addTearDown(repository.dispose);
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(user: user, authController: controller),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('refresh-verification')));
    await tester.pumpAndSettle();

    expect(repository.refreshCalls, 1);
    expect(find.text('Email verified.'), findsOneWidget);
  });

  testWidgets('confirms account deletion with the current password', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(user: user, authController: controller),
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('delete-account-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('delete-account-password')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(repository.lastDeletePassword, 'password123');
  });
}
