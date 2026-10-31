import 'package:firebase_auth/firebase_auth.dart';

import 'auth_account.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<AuthAccount?> authStateChanges() {
    return _auth.authStateChanges().map(_toAccount);
  }

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireAccount(credential.user);
  }

  @override
  Future<AuthAccount> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireAccount(credential.user);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.updateDisplayName(name);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<AuthAccount> reloadAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.reload();
    return _requireAccount(_auth.currentUser);
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> deleteCurrentAccount() async {
    await _auth.currentUser?.delete();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthAccount _requireAccount(User? user) {
    final account = _toAccount(user);
    if (account == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return account;
  }

  AuthAccount? _toAccount(User? user) {
    if (user == null) return null;
    return AuthAccount(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }
}
