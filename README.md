# zollo

**zollo** is an e-commerce marketplace app built with Flutter. It uses Supabase for authentication and data, Riverpod for state management, and GoRouter for navigation. Users can browse products, manage a cart and wishlist, check out with a saved address, view order history, track shipments, and review products they've bought.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Navigation & Routes](#navigation--routes)
- [State Management](#state-management)
- [Backend (Supabase)](#backend-supabase)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Known Limitations / Roadmap](#known-limitations--roadmap)

---

## Tech Stack

| Concern            | Package                                   |
| ------------------ | ----------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.13.5`), Material 3  |
| State management   | `flutter_riverpod` ^3.4.3                 |
| Routing            | `go_router` ^18.1.1                       |
| Backend / Auth / DB| `supabase_flutter` ^2.18.3                |
| Local storage      | `shared_preferences` ^2.2.2               |
| ID generation      | `uuid` ^4.6.0                             |
| Also declared      | `dio`, `cached_network_image` (not used in `lib/` yet) |
| Linting            | `flutter_lints` ^6.0.0                    |

Supported platforms (scaffolded): Android, iOS, Web, macOS, Windows, Linux.

---

## Features

### 1. Splash
- Branded splash screen with the `ZolloLogo`, a tagline and a progress indicator.
- Waits at least 1.5s, then decides where to go:
  - onboarding not done → `/onboarding`
  - signed in → `/home`
  - otherwise → `/login`

### 2. Onboarding
- Multi-page `PageView` intro ("Discover Products", …) with **Next**, **Skip** and **Get Started**.
- Completion is saved in `SharedPreferences` (`OnboardingRepository`), so it only shows once. Logging out does **not** reset it.

### 3. Authentication
- Email/password **Sign Up** (stores `full_name` in user metadata) and **Login** through Supabase Auth.
- `authStateProvider` streams auth state changes; `currentUserProvider` gives the current `User`.
- Shared `AuthFormField` widget for the forms.
- Logout from the Account screen.

### 4. Home
- `HomeHeader` (search/branding header)
- `PromoBanner`: swipeable promo carousel (`PageView`)
- `CategoryRow`: category shortcuts
- `FlashSaleSection`: countdown timer UI plus a horizontal product list
- `JustForYouSection`: product grid

### 5. Products
- Products load from the Supabase `products` table, joined with `categories(name)`. Only `is_active` products are shown, newest first.
- **Fallback queries** keep it working on simpler schemas: if the main query fails, it retries without the `is_active` filter, then with a plain `select *`.
- `Product.fromJson` accepts both the legacy JSON shape and Supabase rows (e.g. `stock_quantity` / `stock` / `quantity`).
- **Product List screen** (Categories tab): search bar and filter chips (Popular, Price, Brand, 4★ & up, Free delivery), shown with `ProductCard`.
- **Product Details screen**: image header with back/share/cart buttons, price and discount badge, rating, **color selection** (Black / White / Navy), stock-aware add to cart, and an inline reviews section.

### 6. Cart
- In-memory cart (`CartController`, a `Notifier<Map<String, CartItem>>`) keyed by product ID.
- Add, increment, decrement (removes the item at 0), remove and clear.
- **Stock guard**: quantity can never go above `product.stock`.
- Derived providers: `cartItemCountProvider`, `cartSubtotalProvider`.
- Flat delivery fee (৳60) is added to the total; there's an empty-cart state.

### 7. Wishlist
- Wishlist is stored in the Supabase `wishlist` table (`product_id` per user).
- `WishlistNotifier` (`AsyncNotifier<Set<String>>`) handles add (upsert) and remove.
- Reusable `WishlistButton` (heart toggle), a Wishlist screen, and a wishlist count on the Account screen.

### 8. Address Book
- Full CRUD on the Supabase `addresses` table: list, add, edit, delete.
- Fields: full name, phone, address line, area, district, division, city, postal code, country, and a label (Home / Office / Other).
- Bangladesh-specific division and district pickers (Dhaka, Chattogram, Sylhet, Rajshahi …).
- **Default address** support (`setDefaultAddress`, `defaultAddressProvider`).
- **Selection mode** (`/addresses?select=true`) for picking an address during checkout.

### 9. Checkout
- Uses the default address, or another one you pick from the address book.
- Payment method: **Cash on Delivery** (default) or **Online**.
- Checks before placing: address present, cart not empty, user signed in.
- Saves a **snapshot of the shipping address** as a string on the order, so editing the address later doesn't change past orders.
- Builds an `OrderModel` (UUID v4 ID, status `pending`) and submits it through `PlaceOrderController`. When it succeeds, the cart is cleared and you go to Order Confirmation.

### 10. Orders
- `OrderRepository` interface with a `SupabaseOrderRepository` implementation.
- Saves to the `orders` table, with items stored inline or in an `order_items` table.
- **Schema-tolerant inserts**: if the DB rejects the `items` or `total_amount` columns, it retries without them and writes `order_items` separately.
- Screens: **Order Confirmation**, **Order History**, **Order Details** (`/order-details/:orderId`).
- `OrderStatus`: `pending → confirmed → processing → shipped → delivered` or `cancelled`.
- Providers: `orderHistoryProvider` (alias `myOrdersProvider`), `orderByIdProvider` / `orderDetailsProvider` (family), `placeOrderProvider`.

### 11. Shipment Tracking
- Reads shipments for an order from `shipments`, and their events from `tracking_events`.
- `Shipment` has a tracking number, courier, status, estimated delivery date and its list of events, sorted by time.
- `ShipmentStatus`: `pending, pickedUp, inTransit, outForDelivery, delivered, exception`.
- `TrackingTimeline` widget shows the events as a vertical timeline (`/tracking/:orderId`).

### 12. Product Reviews & Ratings
- Reviews are stored in the `product_reviews` table (rating 1–5 plus an optional comment), one per user per product (upsert).
- **Verified-purchase gate**: you can only review a product that's in one of your orders that has reached the required status (`canUserReviewProvider`).
- `RatingStars` widget and a `ProductReviewsScreen`. You can also submit a review from Product Details.

### 13. Profile / Account
- Profile header with **Edit Profile** (updates `full_name` / `phone` in Supabase user metadata).
- Order status shortcuts that open Order History.
- Menu: Wishlist (with count), Address book, My vouchers, Messages, Notifications, Help center, Settings, Sell on zollo, Logout.

### 14. Core / Shared
- `AppTheme.light`: Material 3, seed color `#5B4BDB`. The bottom nav accent is `#006B54`.
- `MainScaffold`: bottom navigation bar with 4 tabs (Home, Categories, Cart, Account).
- `ZolloLogo`: reusable brand widget.
- `supabase_client.dart`: global `supabase` client accessor.
- `supabase_test_screen.dart`: a debug screen for checking the Supabase connection.

---

## Architecture

The app is organized **feature-first**, with a light **Clean Architecture** layering inside each feature:

```
┌──────────────────────────────────────────────────────────┐
│ presentation/  screens · widgets · providers (Riverpod)   │  UI + state
├──────────────────────────────────────────────────────────┤
│ domain/        models / entities (+ enums, fromJson)      │  Business objects
├──────────────────────────────────────────────────────────┤
│ data/          repositories (Supabase / SharedPreferences)│  Data access
└──────────────────────────────────────────────────────────┘
```

Key ideas:

- **Repository pattern**: each feature talks to Supabase only through a repository class (`ProductRepository`, `AddressRepository`, `WishlistRepository`, `ReviewRepository`, `TrackingRepository`, `AuthRepository`, `OnboardingRepository`). The orders feature goes one step further with an **abstract interface** (`OrderRepository`) and a concrete `SupabaseOrderRepository`, which makes it easy to swap in a fake for tests.
- **Dependency injection with Riverpod**: every repository is exposed through a `Provider`, so tests can override it (`overrideWithValue` / fake repositories). `SharedPreferences` is created in `main()` and injected by overriding `sharedPreferencesProvider`.
- **Reactive UI**: screens are `ConsumerWidget` / `ConsumerStatefulWidget` and `watch` `FutureProvider` / `AsyncNotifier` state, with loading, error and data states handled through `AsyncValue.when`.
- **Derived state**: values like cart count and subtotal are computed providers, not stored separately.
- **Resilient data layer**: fallback queries and multi-format `fromJson` keep the app running while the Supabase schema is still changing.
- **Declarative routing**: a single `GoRouter` with a `StatefulShellRoute.indexedStack`, so each bottom-nav tab keeps its own navigation stack and state.

### App start flow

```
main()
 ├─ Supabase.initialize(url, publishableKey)   ← --dart-define or default
 ├─ SharedPreferences.getInstance()
 └─ ProviderScope(overrides: [sharedPreferencesProvider])
      └─ MaterialApp.router(theme: AppTheme.light, routerConfig: appRouter)
           └─ /splash → /onboarding | /login | /home
```

### Purchase flow

```
Home / Product List → Product Details → Add to Cart → Cart
  → Checkout (address + payment) → PlaceOrderController → Supabase orders/order_items
  → Order Confirmation → Order History → Order Details → Tracking
                                             └→ Review (verified purchase)
```

---

## Project Structure

```
lib/
├── main.dart                                   # Bootstrap: Supabase.initialize, SharedPreferences, ProviderScope, MyApp (MaterialApp.router)
├── app.dart                                    # Empty placeholder
│
├── core/
│   ├── router/
│   │   ├── app_router.dart                     # GoRouter config: all routes + StatefulShellRoute (bottom tabs)
│   │   └── main_scaffold.dart                  # Bottom navigation shell (Home, Categories, Cart, Account)
│   ├── supabase/
│   │   ├── supabase_client.dart                # Global `supabase` client accessor
│   │   └── supabase_test_screen.dart           # Debug screen to verify Supabase connection
│   ├── theme/
│   │   └── app_theme.dart                      # AppTheme.light (Material 3, seed #5B4BDB)
│   └── widgets/
│       └── zollo_logo.dart                     # Reusable brand logo widget
│
└── features/
    ├── splash/
    │   └── presentation/screens/
    │       └── splash_screen.dart              # Logo + delay, routes to onboarding / login / home
    │
    ├── onboarding/
    │   ├── data/
    │   │   └── onboarding_repository.dart      # SharedPreferences flag (get / set / clear)
    │   └── presentation/
    │       ├── providers/onboarding_provider.dart   # sharedPreferencesProvider, onboardingRepositoryProvider, OnboardingController
    │       ├── screens/onboarding_screen.dart       # PageView with Next / Skip / Get Started
    │       └── widgets/onboarding_page.dart         # Single onboarding slide
    │
    ├── auth/
    │   ├── data/repositories/
    │   │   └── auth_repository.dart            # Supabase signUp, signIn, updateProfile, signOut, authStateChanges
    │   ├── domain/providers/
    │   │   └── auth_provider.dart              # authRepositoryProvider, authStateProvider, currentUserProvider, AuthController
    │   └── presentation/
    │       ├── screens/login_screen.dart       # Email/password login
    │       ├── screens/signup_screen.dart      # Registration with full name
    │       └── widgets/auth_form_field.dart    # Shared text field for auth forms
    │
    ├── home/
    │   └── presentation/
    │       ├── home_screen.dart                # Composes all home sections
    │       └── widgets/
    │           ├── home_header.dart            # Top header / search bar
    │           ├── promo_banner.dart           # Swipeable promo carousel (PageView)
    │           ├── category_row.dart           # Category shortcuts
    │           ├── flash_sale_section.dart     # Countdown + horizontal product list
    │           └── just_for_you_section.dart   # Recommended product grid
    │
    ├── products/
    │   ├── data/repositories/
    │   │   └── product_repository.dart         # Fetch products (+ categories join) with fallback queries
    │   ├── domain/models/
    │   │   └── product.dart                    # Product model, multi-format fromJson
    │   └── presentation/
    │       ├── providers/products_provider.dart       # productRepositoryProvider, productsProvider
    │       ├── screens/product_list_screen.dart       # Search bar + filter chips + product list
    │       ├── screens/product_details_screen.dart    # Details, color selection, add to cart, reviews
    │       └── widgets/product_card.dart              # Product tile used in lists/grids
    │
    ├── cart/
    │   ├── domain/models/
    │   │   └── cart_item.dart                  # CartItem (product, quantity, subtotal)
    │   └── presentation/
    │       ├── providers/cart_provider.dart    # CartController + cartItemCountProvider, cartSubtotalProvider
    │       ├── screens/cart_screen.dart        # Cart list, totals, checkout button, empty state
    │       └── widgets/cart_item_tile.dart     # Cart row with +/- and remove
    │
    ├── wishlist/
    │   ├── data/
    │   │   └── wishlist_repository.dart        # Supabase `wishlist` table: getProductIds, add, remove
    │   ├── domain/
    │   │   └── wishlist_item.dart              # WishlistItem model
    │   └── presentation/
    │       ├── providers/wishlist_provider.dart     # WishlistNotifier (AsyncNotifier<Set<String>>)
    │       ├── screens/wishlist_screen.dart         # Saved products list
    │       └── widgets/wishlist_button.dart         # Heart toggle button
    │
    ├── address/
    │   ├── data/
    │   │   └── address_repository.dart         # Supabase `addresses` CRUD + setDefaultAddress
    │   ├── domain/
    │   │   └── address_model.dart              # Address model (division, district, label, isDefault …)
    │   └── presentation/
    │       ├── providers/address_provider.dart         # addressRepositoryProvider, AddressListNotifier, defaultAddressProvider
    │       ├── screens/address_list_screen.dart        # Address book (normal + select mode)
    │       ├── screens/add_edit_address_screen.dart    # Add / edit address form
    │       └── widgets/address_card.dart               # Address list item
    │
    ├── checkout/
    │   ├── models/
    │   │   └── checkout_order.dart             # PaymentMethod enum, CheckoutOrder
    │   └── screens/
    │       └── checkout_screen.dart            # Address + payment selection, validation, place order
    │
    ├── orders/
    │   ├── data/repositories/
    │   │   ├── order_repository.dart           # Abstract interface: saveOrder, getOrderById, getOrders
    │   │   └── supabase_order_repository.dart  # Supabase implementation (orders + order_items, schema-tolerant)
    │   ├── domain/models/
    │   │   └── order_model.dart                # OrderStatus enum, OrderItem, OrderModel
    │   └── presentation/
    │       ├── providers/order_provider.dart          # orderRepositoryProvider, orderHistoryProvider, orderByIdProvider, PlaceOrderController
    │       ├── providers/order_providers.dart         # Empty stub
    │       ├── screens/order_confirmation_screen.dart # Success screen after placing order
    │       ├── screens/order_history_screen.dart      # List of user's orders
    │       └── screens/order_details_screen.dart      # Single order details
    │
    ├── tracking/
    │   ├── data/
    │   │   └── tracking_repository.dart        # Supabase `shipments` + `tracking_events`
    │   ├── domain/
    │   │   ├── tracking_event_model.dart       # ShipmentStatus enum, TrackingEvent, Shipment
    │   │   └── shipment_model.dart             # Empty stub
    │   ├── providers/
    │   │   └── tracking_provider.dart          # trackingRepositoryProvider + shipment/event providers
    │   └── presentation/
    │       ├── screens/tracking_screen.dart    # Shipment tracking screen
    │       └── widgets/tracking_timeline.dart  # Vertical event timeline
    │
    ├── reviews/
    │   ├── data/
    │   │   └── review_repository.dart          # getReviews, hasUserCompletedOrderForProduct, submitReview (upsert)
    │   ├── domain/
    │   │   └── review.dart                     # ProductReview model
    │   ├── providers/
    │   │   └── review_providers.dart           # reviewRepositoryProvider, productReviewsProvider, canUserReviewProvider
    │   └── presentation/
    │       ├── screens/product_reviews_screen.dart  # All reviews of a product
    │       └── widgets/rating_stars.dart            # Star rating display/input
    │
    └── profile/
        └── presentation/screens/
            ├── profile_screen.dart             # Account tab: header, order shortcuts, menu, logout
            └── edit_profile_screen.dart        # Update full name / phone

test/
├── widget_test.dart                            # App smoke test
├── product_test.dart                           # Product.fromJson formats
├── e2e_marketplace_test.dart                   # Product, cart and order calculations
├── workflow_test.dart                          # Product & order providers with fake repos
├── core/router/
│   └── router_navigation_test.dart             # Splash → Onboarding → Login / Home flows
└── features/
    ├── splash/splash_screen_test.dart
    ├── onboarding/onboarding_repository_test.dart
    ├── onboarding/onboarding_screen_test.dart
    ├── tracking/tracking_test.dart
    ├── wishlist/wishlist_repository_test.dart  # Placeholder
    └── wishlist/wishlist_provider_test.dart    # Placeholder
```

---

## Navigation & Routes

| Route                         | Screen                    | Notes                                   |
| ----------------------------- | ------------------------- | --------------------------------------- |
| `/splash`                     | SplashScreen              | Initial location                        |
| `/onboarding`                 | OnboardingScreen          |                                         |
| `/login`, `/signup`           | Login / Signup            |                                         |
| `/home`                       | HomeScreen                | Shell tab 1                             |
| `/categories`                 | ProductListScreen         | Shell tab 2                             |
| `/cart`                       | CartScreen                | Shell tab 3                             |
| `/account`                    | ProfileScreen             | Shell tab 4                             |
| `/edit-profile`               | EditProfileScreen         |                                         |
| `/wishlist`                   | WishlistScreen            |                                         |
| `/addresses?select=true`      | AddressListScreen         | `select=true` → picker mode             |
| `/add-address`                | AddEditAddressScreen      |                                         |
| `/edit-address`               | AddEditAddressScreen      | `extra: Address`                        |
| `/product-details`            | ProductDetailsScreen      | `extra: Product`                        |
| `/checkout`                   | CheckoutScreen            | `extra: {subtotal, deliveryCharge}`     |
| `/order-confirmation`         | OrderConfirmationScreen   | `extra: OrderModel`                     |
| `/order-history`              | OrderHistoryScreen        |                                         |
| `/order-details/:orderId`     | OrderDetailsScreen        |                                         |
| `/tracking/:orderId`          | TrackingScreen            |                                         |

---

## State Management

| Provider                                   | Type                                  | Purpose                         |
| ------------------------------------------ | ------------------------------------- | ------------------------------- |
| `sharedPreferencesProvider`                | `Provider<SharedPreferences>`         | Overridden in `main()`          |
| `onboardingRepositoryProvider` / `OnboardingController` | `Provider` / `AsyncNotifier<bool>` | Onboarding flag     |
| `authRepositoryProvider`, `authStateProvider`, `currentUserProvider`, `AuthController` | Provider / StreamProvider / AsyncNotifier | Auth |
| `productRepositoryProvider`, `productsProvider` | `Provider` / `FutureProvider<List<Product>>` | Product catalog   |
| `cartProvider` (`CartController`)          | `NotifierProvider`                    | Cart state                      |
| `cartItemCountProvider`, `cartSubtotalProvider` | `Provider`                       | Derived cart values             |
| `WishlistNotifier`                         | `AsyncNotifier<Set<String>>`          | Wishlist product IDs            |
| `addressRepositoryProvider`, `AddressListNotifier`, `defaultAddressProvider` | Provider / AsyncNotifier / FutureProvider | Addresses |
| `orderRepositoryProvider`, `orderHistoryProvider`, `orderByIdProvider`, `orderDetailsProvider`, `PlaceOrderController` | Provider / FutureProvider(.family) / AsyncNotifier | Orders |
| `trackingRepositoryProvider` (+ tracking providers) | `Provider` / `FutureProvider`  | Shipments & events              |
| `reviewRepositoryProvider`, `productReviewsProvider`, `canUserReviewProvider` | Provider / FutureProvider | Reviews |

---

## Backend (Supabase)

Tables the app uses:

| Table              | Used by                     | Main columns (as read by the app)                                   |
| ------------------ | --------------------------- | ------------------------------------------------------------------- |
| `products`         | ProductRepository           | id, title/name, description, price, image, `category_id`, rating, `stock_quantity`, `is_active`, `created_at` |
| `categories`       | joined from products        | name                                                                |
| `wishlist`         | WishlistRepository          | user_id, product_id                                                 |
| `addresses`        | AddressRepository           | user_id, full_name, phone, address_line, area, district, division, city, postal_code, country, label, is_default |
| `orders`           | SupabaseOrderRepository     | id, user_id, shipping_address, shipping_fee, status, total_amount, created_at, (items) |
| `order_items`      | Orders, Reviews             | order_id, product_id, product_name, price, quantity                 |
| `shipments`        | TrackingRepository          | order_id, tracking_number, courier_name, status, estimated_delivery_date |
| `tracking_events`  | TrackingRepository          | shipment_id, status, description, location, timestamp              |
| `product_reviews`  | ReviewRepository            | product_id, user_id, rating, comment, created_at                    |

Auth: Supabase email/password. Profile data (`full_name`, `phone`) is kept in the auth user's metadata.

> Row Level Security should restrict `wishlist`, `addresses`, `orders`, `order_items` and `product_reviews` to `auth.uid()`.

---

## Getting Started

### Prerequisites
- Flutter SDK with Dart `>= 3.13.5`
- A Supabase project with the tables above

### Install & run

```bash
flutter pub get

# Uses the default Supabase project baked into main.dart
flutter run

# Or point to your own Supabase project
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-anon-or-publishable-key>
```

---

## Testing

```bash
flutter test
```

| Test file                                              | Covers                                                    |
| ------------------------------------------------------ | --------------------------------------------------------- |
| `test/product_test.dart`                               | `Product.fromJson` with legacy and Supabase row formats   |
| `test/e2e_marketplace_test.dart`                       | Product parsing, cart add/subtotal/count/clear, order totals |
| `test/workflow_test.dart`                              | `productsProvider` and order providers with fake repositories, place-order invalidation |
| `test/core/router/router_navigation_test.dart`         | Splash → Onboarding → Login flow, signed-in user → Home, logout keeps onboarding done, no redirect loop |
| `test/features/splash/splash_screen_test.dart`         | Splash rendering and navigation                           |
| `test/features/onboarding/*`                           | Repository persistence, page flow, Skip / Get Started     |
| `test/features/tracking/tracking_test.dart`            | Model serialization, event sorting, timeline widget       |
| `test/features/wishlist/*`                             | Placeholders                                              |
| `test/widget_test.dart`                                | App smoke test                                            |

---

## Known Limitations / Roadmap

- The cart lives only in memory, so it's lost on restart. It isn't saved to Supabase yet.
- Product List filter chips and search are UI only; they don't filter results yet.
- Product color selection is hardcoded (Black / White / Navy).
- The **Online** payment method has no payment gateway behind it yet.
- These Account menu items are placeholders: Vouchers, Messages, Notifications, Help center, Settings, Sell on zollo.
- Delivery fee is inconsistent: ৳60 in the cart and router, while `CheckoutScreen` defaults to ৳120.
- `tracking/domain/shipment_model.dart` and `orders/presentation/providers/order_providers.dart` are empty stubs.
- `dio` and `cached_network_image` are declared but not used.
- Only a light theme exists, and there's no route guard. Auth redirects are handled by the splash screen.
- Wishlist tests are placeholders.
