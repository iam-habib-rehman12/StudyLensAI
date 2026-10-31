import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;
  AuthState _state = const AuthState.checking();
  StreamSubscription<AppUser?>? _authSubscription;
  bool _initialized = false;

  AuthState get state => _state;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = _repository.authStateChanges().listen(
      _onAuthChanged,
      onError: _onAuthStreamError,
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _repository.signIn(email: email, password: password);
      _setAuthenticated(user);
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError('StudyLens could not sign you in. Please try again.');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      _setAuthenticated(user);
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not create your account. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    if (_state.isSubmitting) return;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.signOut();
      _setState(const AuthState(status: AuthStatus.unauthenticated));
    } on AppException catch (error) {
      _setSubmissionError(error.message);
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not sign you out. Please try again.',
      );
    }
  }

  Future<bool> refreshUser() async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _repository.refreshUser();
      _setAuthenticated(user);
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not refresh your account. Please try again.',
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.sendPasswordResetEmail(email);
      _setState(_state.copyWith(isSubmitting: false));
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not send the reset email. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.sendEmailVerification();
      _setState(_state.copyWith(isSubmitting: false));
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not send the verification email. Please try again.',
      );
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    if (_state.isSubmitting) return false;
    _setState(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.deleteAccount(password: password);
      _setState(const AuthState(status: AuthStatus.unauthenticated));
      return true;
    } on AppException catch (error) {
      _setSubmissionError(error.message);
      return false;
    } catch (_) {
      _setSubmissionError(
        'StudyLens could not delete your account. Sign in again and retry.',
      );
      return false;
    }
  }

  void clearError() {
    if (_state.errorMessage == null) return;
    _setState(_state.copyWith(clearError: true));
  }

  void _onAuthChanged(AppUser? user) {
    if (user == null) {
      _setState(const AuthState(status: AuthStatus.unauthenticated));
    } else {
      _setAuthenticated(user);
    }
  }

  void _onAuthStreamError(Object _) {
    _setState(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'StudyLens could not check your account status.',
      ),
    );
  }

  void _setAuthenticated(AppUser user) {
    _setState(AuthState(status: AuthStatus.authenticated, user: user));
  }

  void _setSubmissionError(String message) {
    _setState(_state.copyWith(isSubmitting: false, errorMessage: message));
  }

  void _setState(AuthState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
