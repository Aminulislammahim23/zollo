import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Re-authenticates with [currentPassword], then sets [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    bool signOutOtherDevices = false,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw StateError('Please log in again to change your password.');
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));

    if (signOutOtherDevices) {
      await _client.auth.signOut(scope: SignOutScope.others);
    }
  }

  Future<UserResponse> updateProfile({
    required String fullName,
    String? phone,
    String? gender,
    String? birthday,
  }) {
    final Map<String, dynamic> updateData = {'full_name': fullName.trim()};

    if (gender != null) updateData['gender'] = gender;
    if (birthday != null) updateData['birthday'] = birthday;
    if (phone != null) updateData['phone'] = phone;

    return _client.auth.updateUser(UserAttributes(data: updateData));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
