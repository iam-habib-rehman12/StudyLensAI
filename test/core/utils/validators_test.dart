import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/utils/validators.dart';

void main() {
  test('validates email structure', () {
    expect(Validators.email('student@example.com'), isNull);
    expect(Validators.email('student'), 'Enter a valid email address.');
  });

  test('requires an eight character password', () {
    expect(Validators.password('12345678'), isNull);
    expect(
      Validators.password('short'),
      'Password must contain at least 8 characters.',
    );
  });

  test('requires matching password confirmation', () {
    expect(Validators.confirmPassword('password', 'password'), isNull);
    expect(
      Validators.confirmPassword('different', 'password'),
      'Passwords do not match.',
    );
  });
}
