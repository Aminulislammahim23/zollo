import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
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

  Future<UserResponse> updateProfile({
    required String fullName,
    String? phone,
    String? gender,
    String? birthday,
  }) {
    final Map<String, dynamic> updateData = {
      'full_name': fullName.trim(),
    };

    if (gender != null) updateData['gender'] = gender;
    if (birthday != null) updateData['birthday'] = birthday;
    if (phone != null) updateData['phone'] = phone;

    return _client.auth.updateUser(
      UserAttributes(
        data: updateData,
      ),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
