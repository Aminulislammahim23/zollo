import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../debug/style_preview_screen.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/vouchers/presentation/screens/vouchers_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/products/presentation/screens/product_details_screen.dart';
import '../../features/products/domain/models/product.dart';
import '../../features/reviews/presentation/screens/product_reviews_screen.dart';
import '../../features/reviews/presentation/screens/write_review_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/orders/presentation/screens/order_confirmation_screen.dart';
import '../../features/orders/domain/models/order_model.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/address/presentation/screens/address_list_screen.dart';
import '../../features/address/presentation/screens/add_edit_address_screen.dart';
import '../../features/address/domain/address_model.dart';
import 'main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    if (kDebugMode)
      GoRoute(
        path: '/style-preview',
        builder: (context, state) => const StylePreviewScreen(),
      ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/settings/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(
      path: '/addresses',
      builder: (context, state) {
        final isSelecting = state.uri.queryParameters['select'] == 'true';
        return AddressListScreen(isSelecting: isSelecting);
      },
    ),
    GoRoute(
      path: '/add-address',
      builder: (context, state) => const AddEditAddressScreen(),
    ),
    GoRoute(
      path: '/edit-address',
      builder: (context, state) {
        final address = state.extra as Address;
        return AddEditAddressScreen(address: address);
      },
    ),
    GoRoute(
      path: '/vouchers',
      builder: (context, state) => const VouchersScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => ProductListScreen(
        categoryId: state.uri.queryParameters['category'],
        query: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/product-details',
      builder: (context, state) {
        final product = state.extra as Product;
        return ProductDetailsScreen(product: product);
      },
    ),
    GoRoute(
      path: '/product-reviews',
      builder: (context, state) => ProductReviewsScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/write-review',
      builder: (context, state) => WriteReviewScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final subtotal = extras?['subtotal'] as double? ?? 0.0;
        final deliveryCharge = extras?['deliveryCharge'] as double? ?? AppConstants.deliveryFee;
        return CheckoutScreen(subtotal: subtotal, deliveryCharge: deliveryCharge);
      },
    ),
    GoRoute(
      path: '/order-history',
      builder: (context, state) => OrderHistoryScreen(
        initialTab: OrderTab.fromQuery(state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(
      path: '/order-details/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailsScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderConfirmationScreen(order: order);
      },
    ),
    GoRoute(
      path: '/tracking/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return TrackingScreen(orderId: orderId);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(
          navigationShell: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
