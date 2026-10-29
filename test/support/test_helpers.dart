import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zollo/core/theme/app_theme.dart';
import 'package:zollo/features/auth/data/repositories/auth_repository.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zollo/features/products/domain/models/product.dart';
import 'package:zollo/features/wishlist/data/wishlist_repository.dart';
import 'package:zollo/features/wishlist/presentation/providers/wishlist_provider.dart';

class FakeUser extends User {
  FakeUser({String email = 'rahim@example.com', Map<String, dynamic>? metadata})
      : super(
          id: 'user-1',
          appMetadata: const {},
          userMetadata: metadata ?? const {'full_name': 'Rahim Uddin', 'phone': '+8801712345678'},
          aud: 'authenticated',
          email: email,
          createdAt: DateTime(2026).toIso8601String(),
          emailConfirmedAt: DateTime(2026).toIso8601String(),
        );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.error, this.requireConfirmation = false});

  User? user;
  Object? error;
  bool requireConfirmation;
  final calls = <String>[];

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => user;

  Future<void> _maybeThrow(String call) async {
    calls.add(call);
    if (error != null) throw error!;
  }

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    await _maybeThrow('signIn');
    user = FakeUser(email: email);
    return AuthResponse(user: user, session: Session(accessToken: 't', tokenType: 'bearer', user: user!));
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    await _maybeThrow('signUp:$phone');
    final newUser = FakeUser(email: email);
    if (requireConfirmation) return AuthResponse(user: newUser);
    user = newUser;
    return AuthResponse(user: user, session: Session(accessToken: 't', tokenType: 'bearer', user: user!));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) => _maybeThrow('reset:$email');

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    bool signOutOtherDevices = false,
  }) =>
      _maybeThrow('changePassword:$signOutOtherDevices');

  @override
  Future<UserResponse> updateProfile({
    required String fullName,
    String? phone,
    String? gender,
    String? birthday,
  }) async {
    await _maybeThrow('updateProfile:$fullName:$phone');
    return UserResponse.fromJson({'id': 'user-1', 'aud': 'authenticated', 'created_at': '2026-01-01', 'app_metadata': {}, 'user_metadata': {'full_name': fullName}});
  }

  @override
  Future<void> signOut() => _maybeThrow('signOut');
}

class FakeWishlistRepository implements WishlistRepository {
  FakeWishlistRepository([Set<String>? ids]) : ids = ids ?? {};

  final Set<String> ids;

  @override
  Future<Set<String>> getProductIds() async => Set.of(ids);

  @override
  Future<void> add(String productId) async => ids.add(productId);

  @override
  Future<void> remove(String productId) async => ids.remove(productId);
}

Product sampleProduct({
  String id = 'p1',
  String title = 'Wireless Bluetooth Earbuds',
  double price = 1850,
  int stock = 10,
  double rating = 4.5,
  String category = 'Electronics',
  String categoryId = 'c1',
  double? originalPrice,
}) =>
    Product(
      id: id,
      title: title,
      description: 'Noise isolating earbuds with 24 hour battery life.',
      price: price,
      imageUrl: '',
      category: category,
      rating: rating,
      stock: stock,
      categoryId: categoryId,
      originalPrice: originalPrice,
    );

/// Builds a themed app around [routes] with the common providers faked.
Future<void> pumpRoutes(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initialLocation,
  List overrides = const [],
  User? user,
  FakeAuthRepository? auth,
  FakeWishlistRepository? wishlist,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final authRepo = auth ?? FakeAuthRepository(user: user);

  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        authRepositoryProvider.overrideWithValue(authRepo),
        currentUserProvider.overrideWith((ref) {
          ref.watch(authControllerProvider);
          return authRepo.currentUser;
        }),
        wishlistRepositoryProvider.overrideWithValue(wishlist ?? FakeWishlistRepository()),
        ...overrides.cast(),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
}

/// A placeholder destination that just shows [label].
GoRoute stubRoute(String path, [String? label]) => GoRoute(
      path: path,
      builder: (context, state) => Scaffold(body: Text(label ?? 'Route $path')),
    );
