abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? requiredName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length < 2) return 'Name must contain at least 2 characters.';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 8) {
      return 'Password must contain at least 8 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }
}
