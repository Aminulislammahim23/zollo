import 'package:supabase_flutter/supabase_flutter.dart';

/// Form validators and plain-language auth error messages.
abstract final class AuthValidators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(text)) return 'Enter a valid email, e.g. you@example.com';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password';
    if (text.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your full name';
    if (text.length < 2) return 'Name is too short';
    return null;
  }

  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasNumber(String value) => value.contains(RegExp(r'\d'));
  static bool hasUppercase(String value) => value.contains(RegExp('[A-Z]'));

  /// Password rules from spec C5: length, a number, an uppercase letter.
  static String? strongPassword(String? value) {
    final text = value ?? '';
    if (!hasMinLength(text)) return 'Use at least 8 characters';
    if (!hasNumber(text)) return 'Add at least one number';
    if (!hasUppercase(text)) return 'Add at least one uppercase letter';
    return null;
  }

  /// 0–4 for the sign-up strength bar, from length and character mix.
  static int strength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (hasNumber(value)) score++;
    if (hasUppercase(value) && value.contains(RegExp('[a-z]'))) score++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]')) || value.length >= 12) score++;
    return score.clamp(1, 4);
  }

  static String message(Object error) {
    if (error is AuthException) {
      final code = error.code ?? '';
      final text = error.message.toLowerCase();
      if (code == 'invalid_credentials' || text.contains('invalid login credentials')) {
        return 'That email and password do not match. Try again.';
      }
      if (code == 'email_not_confirmed' || text.contains('email not confirmed')) {
        return 'Please confirm your email first. Check your inbox for the link.';
      }
      if (code == 'user_already_exists' || text.contains('already registered')) {
        return 'An account with this email already exists. Try logging in.';
      }
      if (code == 'weak_password' || text.contains('password should')) {
        return 'That password is too weak. Use 8+ characters with a number and a capital letter.';
      }
      if (code.contains('rate_limit') || error.statusCode == '429') {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      if (code == 'same_password') {
        return 'Your new password must be different from the current one.';
      }
      return error.message;
    }
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return text.replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
  }
}
