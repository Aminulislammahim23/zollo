import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/address/domain/address_model.dart';
import 'package:zollo/features/address/presentation/providers/address_provider.dart';
import 'package:zollo/features/address/presentation/screens/add_edit_address_screen.dart';
import 'package:zollo/features/address/presentation/screens/address_list_screen.dart';
import 'package:zollo/features/auth/presentation/screens/change_password_screen.dart';
import 'package:zollo/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:zollo/features/auth/presentation/screens/login_screen.dart';
import 'package:zollo/features/auth/presentation/screens/signup_screen.dart';
import 'package:zollo/features/cart/presentation/providers/cart_provider.dart';
import 'package:zollo/features/cart/presentation/screens/cart_screen.dart';
import 'package:zollo/features/categories/domain/category.dart';
import 'package:zollo/features/categories/presentation/providers/categories_provider.dart';
import 'package:zollo/features/categories/presentation/screens/categories_screen.dart';
import 'package:zollo/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:zollo/features/chat/presentation/screens/messages_screen.dart';
import 'package:zollo/features/checkout/screens/checkout_screen.dart';
import 'package:zollo/features/home/presentation/home_screen.dart';
import 'package:zollo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:zollo/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:zollo/features/orders/domain/models/order_model.dart';
import 'package:zollo/features/orders/presentation/providers/order_provider.dart';
import 'package:zollo/features/orders/presentation/screens/order_confirmation_screen.dart';
import 'package:zollo/features/orders/presentation/screens/order_details_screen.dart';
import 'package:zollo/features/orders/presentation/screens/order_history_screen.dart';
import 'package:zollo/features/products/presentation/providers/products_provider.dart';
import 'package:zollo/features/products/presentation/screens/product_details_screen.dart';
import 'package:zollo/features/products/presentation/screens/product_list_screen.dart';
import 'package:zollo/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:zollo/features/profile/presentation/screens/profile_screen.dart';
import 'package:zollo/features/returns/presentation/screens/return_request_screen.dart';
import 'package:zollo/features/reviews/presentation/screens/product_reviews_screen.dart';
import 'package:zollo/features/reviews/presentation/screens/write_review_screen.dart';
import 'package:zollo/features/reviews/providers/review_providers.dart';
import 'package:zollo/features/search/presentation/screens/search_screen.dart';
import 'package:zollo/features/settings/presentation/screens/settings_screen.dart';
import 'package:zollo/features/splash/presentation/screens/splash_screen.dart';
import 'package:zollo/features/tracking/domain/tracking_event_model.dart';
import 'package:zollo/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:zollo/features/tracking/providers/tracking_provider.dart';
import 'package:zollo/features/vouchers/presentation/screens/vouchers_screen.dart';
import 'package:zollo/features/wishlist/presentation/screens/wishlist_screen.dart';

import 'support/test_helpers.dart';
import 'workflow_test.dart' show FakeOrderRepository;

/// Rule A2.6 / Prompt 16: every screen renders at 360dp wide with the system
/// font at 1.3× without overflow errors.
void main() {
  final product = sampleProduct(
    title: 'Wireless Bluetooth Earbuds with Noise Isolation and Charging Case',
    originalPrice: 2400,
  );
  final order = OrderModel(
    id: 'order-12345',
    userId: 'user-1',
    items: const [
      OrderItem(
        productId: 'p1',
        productName: 'Wireless Bluetooth Earbuds with a long name',
        price: 1850,
        quantity: 2,
      ),
      OrderItem(
        productId: 'p2',
        productName: 'Charger',
        price: 650,
        quantity: 1,
      ),
    ],
    shippingAddress: 'Rahim Uddin · 01712345678\nHouse 12, Road 4, Dhanmondi, Dhaka City, Dhaka',
    shippingFee: 60,
    status: OrderStatus.delivered,
    createdAt: DateTime(2026, 10, 13),
  );
  final address = Address(
    id: 'a1',
    userId: 'user-1',
    fullName: 'Rahim Uddin',
    phone: '01712345678',
    addressLine: 'House 12, Road 4',
    city: 'Dhaka City',
    postalCode: '',
    area: 'Dhanmondi',
    isDefault: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final screens = <String, Widget Function()>{
    'splash': () =>
        const SplashScreen(splashDelay: Duration(milliseconds: 300)),
    'onboarding': () => const OnboardingScreen(),
    'login': () => const LoginScreen(),
    'signup': () => const SignupScreen(),
    'forgot': () => const ForgotPasswordScreen(),
    'change-password': () => const ChangePasswordScreen(),
    'home': () => const HomeScreen(),
    'categories': () => const CategoriesScreen(),
    'products': () => const ProductListScreen(),
    'details': () => ProductDetailsScreen(product: product),
    'reviews': () => ProductReviewsScreen(product: product),
    'write-review': () => WriteReviewScreen(product: product),
    'cart': () => const CartScreen(),
    'checkout': () => const CheckoutScreen(subtotal: 0),
    'confirmation': () => OrderConfirmationScreen(order: order),
    'orders': () => const OrderHistoryScreen(),
    'order-details': () => OrderDetailsScreen(orderId: order.id),
    'tracking': () => TrackingScreen(orderId: order.id),
    'return': () => ReturnRequestScreen(order: order),
    'wishlist': () => const WishlistScreen(),
    'account': () => const ProfileScreen(),
    'edit-profile': () => const EditProfileScreen(),
    'addresses': () => const AddressListScreen(),
    'add-address': () => const AddEditAddressScreen(),
    'search': () => const SearchScreen(),
    'vouchers': () => const VouchersScreen(),
    'notifications': () => const NotificationsScreen(),
    'messages': () => const MessagesScreen(),
    'chat': () => const ChatRoomScreen(conversationId: 'c1'),
    'settings': () => const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits 360dp at 1.3× text', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpRoutes(
        tester,
        routes: [
          GoRoute(path: '/screen', builder: (_, _) => entry.value()),
          stubRoute('/onboarding'),
          stubRoute('/login'),
          stubRoute('/home'),
        ],
        initialLocation: '/screen',
        user: FakeUser(),
        overrides: [
          productsProvider.overrideWith(
            (ref) async => [product, sampleProduct(id: 'p2', title: 'Charger')],
          ),
          categoriesProvider.overrideWith(
            (ref) async => const [
              Category(id: 'c1', name: 'Electronics'),
              Category(id: 'c2', name: 'Home & Living'),
            ],
          ),
          productReviewsProvider.overrideWith((ref, id) async => []),
          canUserReviewProvider.overrideWith((ref, id) async => true),
          defaultAddressProvider.overrideWith((ref) async => address),
          addressListProvider.overrideWith(() => _FixedAddresses([address])),
          orderRepositoryProvider.overrideWithValue(
            FakeOrderRepository([order]),
          ),
          shipmentsByOrderProvider.overrideWith(
            (ref, id) async => <Shipment>[],
          ),
        ],
      );
      final element = tester.element(
        find.byType(entry.value().runtimeType).first,
      );
      ProviderScope.containerOf(element)
          .read(cartProvider.notifier)
          .addToCart(product, variant: 'Colour: Black');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Overflow errors are reported by the framework and fail the test.
    });
  }
}

class _FixedAddresses extends AddressListNotifier {
  _FixedAddresses(this.addresses);
  final List<Address> addresses;

  @override
  Future<List<Address>> build() async => addresses;
}
