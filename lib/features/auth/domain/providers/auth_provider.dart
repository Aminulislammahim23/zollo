import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// The signed-in user. Rebuilds on every auth event (login, logout, profile
/// update), so screens and user-scoped providers can simply watch it.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  try {
    return ref.watch(authRepositoryProvider).currentUser;
  } catch (_) {
    // Supabase is not initialised (e.g. in unit tests).
    return null;
  }
});

/// Display helpers read from the user's metadata.
extension UserProfileX on User {
  String get displayName {
    final name =
        (userMetadata?['full_name'] ?? userMetadata?['name']) as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return email?.split('@').first ?? 'zollo shopper';
  }

  String? get phoneNumber {
    final metaPhone = userMetadata?['phone'] as String?;
    if (metaPhone != null && metaPhone.isNotEmpty) return metaPhone;
    return (phone != null && phone!.isNotEmpty) ? phone : null;
  }

  String get initial =>
      displayName.isEmpty ? 'Z' : displayName[0].toUpperCase();

  bool get isEmailVerified => emailConfirmedAt != null;
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    return _repository.currentUser;
  }

  /// Returns the response, or null when sign-up failed (see [state] error).
  /// `response.session == null` means Supabase wants the email confirmed.
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncLoading();

    AuthResponse? response;
    state = await AsyncValue.guard(() async {
      response = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      return response!.session == null ? null : response!.user;
    });
    return state.hasError ? null : response;
  }

  /// Returns true when the user is signed in.
  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await _repository.signIn(
        email: email,
        password: password,
      );

      return response.user;
    });
    return !state.hasError && state.value != null;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _repository.sendPasswordResetEmail(email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    bool signOutOtherDevices = false,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      signOutOtherDevices: signOutOtherDevices,
    );
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? gender,
    String? birthday,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        gender: gender,
        birthday: birthday,
      );
      return response.user;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
  }
}
