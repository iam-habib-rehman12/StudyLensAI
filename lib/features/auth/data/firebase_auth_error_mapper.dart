import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';

abstract final class FirebaseAuthErrorMapper {
  static AppException map(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => AppException(
        type: AppErrorType.authentication,
        message: 'Enter a valid email address.',
        cause: error,
      ),
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => AppException(
        type: AppErrorType.authentication,
        message: 'The email or password is incorrect.',
        cause: error,
      ),
      'email-already-in-use' => AppException(
        type: AppErrorType.authentication,
        message: 'An account already exists for this email.',
        cause: error,
      ),
      'weak-password' => AppException(
        type: AppErrorType.authentication,
        message: 'Choose a stronger password with at least 8 characters.',
        cause: error,
      ),
      'user-disabled' => AppException(
        type: AppErrorType.authentication,
        message: 'This account has been disabled.',
        cause: error,
      ),
      'network-request-failed' => AppException(
        type: AppErrorType.offline,
        message: 'No internet connection. Check your network and try again.',
        cause: error,
      ),
      'too-many-requests' => AppException(
        type: AppErrorType.rateLimited,
        message: 'Too many attempts. Please wait and try again.',
        cause: error,
      ),
      'requires-recent-login' ||
      'user-token-expired' => AppException(
        type: AppErrorType.authentication,
        message: 'Sign in again before deleting your account.',
        cause: error,
      ),
      'operation-not-allowed' => AppException(
        type: AppErrorType.configuration,
        message:
            'Email/password sign-in is not enabled for this Firebase project.',
        cause: error,
      ),
      _ => AppException(
        type: AppErrorType.authentication,
        message:
            'StudyLens could not complete authentication. Please try again.',
        cause: error,
      ),
    };
  }
}
