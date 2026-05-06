class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? v) {
    final req = requiredField(v, label: 'Email');
    if (req != null) return req;
    if (!_email.hasMatch(v!.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    final req = requiredField(v, label: 'Password');
    if (req != null) return req;
    if (v!.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? password, String? confirm) {
    final req = requiredField(confirm, label: 'Confirm Password');
    if (req != null) return req;
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  static PasswordStrength strength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return PasswordStrength.values[score.clamp(0, 4)];
  }
}

enum PasswordStrength { none, weak, moderate, strong, veryStrong }

