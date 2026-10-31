class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.isEmailVerified = false,
  });

  final String uid;
  final String name;
  final String email;
  final bool isEmailVerified;
}
