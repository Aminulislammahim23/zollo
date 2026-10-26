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

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<User?> {
  late final AuthRepository _repository;

  @override
  Future<User?> build() async {
    _repository = ref.read(authRepositoryProvider);
    return _repository.currentUser;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      return response.user;
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await _repository.signIn(
        email: email,
        password: password,
      );

      return response.user;
    });
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
