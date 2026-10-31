class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final bool emailVerified;
}
