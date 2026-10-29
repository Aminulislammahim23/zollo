import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/address/domain/address_model.dart';
import '../../features/address/presentation/screens/add_edit_address_screen.dart';
import '../../features/address/presentation/screens/address_list_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/presentation/screens/messages_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/orders/domain/models/order_model.dart';
import '../../features/orders/presentation/screens/order_confirmation_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/products/domain/models/product.dart';
import '../../features/products/presentation/screens/product_details_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/returns/presentation/screens/return_request_screen.dart';
import '../../features/reviews/presentation/screens/product_reviews_screen.dart';
import '../../features/reviews/presentation/screens/write_review_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/vouchers/presentation/screens/vouchers_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../constants/app_constants.dart';
import '../debug/style_preview_screen.dart';
import 'main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    if (kDebugMode)
      GoRoute(
        path: '/style-preview',
        builder: (context, state) => const StylePreviewScreen(),
      ),

    // Start-up and auth
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

    // Catalogue
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
      builder: (context, state) => ProductDetailsScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/product-reviews',
      builder: (context, state) => ProductReviewsScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/write-review',
      builder: (context, state) => WriteReviewScreen(product: state.extra as Product),
    ),

    // Checkout and orders
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
      path: '/order-confirmation',
      builder: (context, state) => OrderConfirmationScreen(order: state.extra as OrderModel),
    ),
    GoRoute(
      path: '/order-history',
      builder: (context, state) => OrderHistoryScreen(
        initialTab: OrderTab.fromQuery(state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(
      path: '/order-details/:orderId',
      builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/tracking/:orderId',
      builder: (context, state) => TrackingScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/return-request',
      builder: (context, state) => ReturnRequestScreen(order: state.extra as OrderModel),
    ),

    // Account
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
      builder: (context, state) => AddressListScreen(
        isSelecting: state.uri.queryParameters['select'] == 'true',
      ),
    ),
    GoRoute(
      path: '/add-address',
      builder: (context, state) => const AddEditAddressScreen(),
    ),
    GoRoute(
      path: '/edit-address',
      builder: (context, state) => AddEditAddressScreen(address: state.extra as Address),
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
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
      routes: [
        GoRoute(
          path: ':conversationId',
          builder: (context, state) => ChatRoomScreen(
            conversationId: state.pathParameters['conversationId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
      ],
    ),

    // Bottom-nav tabs
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
