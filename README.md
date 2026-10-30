# zollo

**zollo** is an e-commerce marketplace app for Bangladesh, built with Flutter. It uses Supabase for authentication and data, Riverpod for state, and GoRouter for navigation. Shoppers can browse and search products, keep a cart and wishlist, check out with cash on delivery, follow their orders, review products, and manage their account.

The UI follows the design spec in [docs/ui_build_plan.md](docs/ui_build_plan.md): one set of colour, type and spacing tokens, shared widgets, and a written spec for each screen.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Design System](#design-system)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Navigation & Routes](#navigation--routes)
- [Backend (Supabase)](#backend-supabase)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Known Limitations / Roadmap](#known-limitations--roadmap)

---

## Tech Stack

| Concern             | Package                                          |
| ------------------- | ------------------------------------------------ |
| Framework           | Flutter (Dart SDK `^3.13.5`), Material 3         |
| State management    | `flutter_riverpod` ^3.4.3                        |
| Routing             | `go_router` ^18.1.1                              |
| Backend / Auth / DB | `supabase_flutter` ^2.18.3                       |
| Images              | `cached_network_image` ^4.0.5                    |
| Local storage       | `shared_preferences` ^2.2.2                      |
| Links / email       | `url_launcher` ^6.3.3                            |
| IDs                 | `uuid` ^4.6.0                                    |
| Font                | Manrope (bundled variable font, OFL licence)     |

---

## Design System

Everything lives in `lib/core/theme/` and `lib/core/widgets/`. Screens use these tokens only; no screen file contains a raw colour or font size.

- **Colours** (`AppColors`): primary `#8A1C5E` (plum), accent `#F5B301` (deal yellow), deep `#2A1023` (campaign banners), ink and muted greys, plus status colours (`warning`, `error`, `discountBg`, …).
- **Type** (`AppText`): Manrope, with `display`, `headline`, `title`, `section`, `body`, `caption`, `price`, `priceOld` and named helper styles.
- **Spacing and shape** (`AppSpacing`, `AppRadius`, `AppBorders`): 4 / 8 / 12 / 16 / 24 / 32 spacing; radius 12 for buttons and inputs, 14 for cards, 16 for banners, 10 for tiles. The style is flat, with no shadows.
- **Helpers**: `formatTaka(2450)` → `৳2,450`, `formatSold`, `formatDate`, `formatRelative`, `formatOrderNumber`. The delivery fee comes from the `app_config` table at start-up (`deliveryFeeProvider`), with `AppConstants.deliveryFee = 60` as the fallback.
- **Shared widgets**: `AppButton` (primary / outline / deal / danger, loading state), `AppTextField`, `PasswordField`, `PhoneField` (+880, BD validation), `SearchField`, `AppChip`, `DiscountBadge`, `PriceText`, `RatingRow`, `ProductCard`, `SliverProductGrid`, `QuantityStepper`, `SectionHeader`, `AppTopBar`, `InfoCard`, `EmptyState`, `ErrorView`, `ShimmerBox`, `StatusText`, `AppBottomNav`, `CartIconButton`, `DashedBorder`, `ZolloLogo`.
- **Style preview**: in debug builds, `/style-preview` shows every colour, text style and widget on one screen.

Every screen handles loading (shimmer), empty (`EmptyState`) and error (`ErrorView` with *Try again*) states. Icon-only buttons have tooltips, and a test renders every screen at 360dp width with 1.3× text without overflow.

---

## Features

### Start-up and account access
- **Splash**: plum brand screen; after 1.5s it routes to onboarding, home or login.
- **Onboarding**: 3 slides (products, payments, tracking) with Skip / Next / Get started. Completion is saved in SharedPreferences.
- **Log in / Sign up**: inline validation, plain-language Supabase errors, an optional BD phone saved to user metadata, a password strength bar, a required terms checkbox, a "Check your email" state when confirmation is on, and *Continue as guest*.
- **Forgot password**: sends a Supabase reset email, then shows a "Check your inbox" state.
- **Change password**: re-authenticates first, shows a live rules checklist, and can log out other devices.

### Shopping
- **Home**: a header with "Deliver to <area>" and a notification bell with an unread badge; campaign banner carousel; categories from Supabase; a flash sale with a live countdown and stock bars; a "Just for you" grid; pull to refresh.
- **Categories tab**: a category rail on the left and a panel on the right with products and "See all".
- **Product list** (`/products?category=&q=`): live search, Popular / price ↑↓ sorting, a 4★ & up filter, a filter sheet (price range + categories) and a result count.
- **Search**: suggestions with the matched text highlighted (300ms debounce), up to 8 recent searches with Clear, and a trending list.
- **Product details**: image header (back / share / cart / wishlist), discount badge, colour options, delivery info, review summary, a collapsible description, and a sticky bar with chat / Add to cart / Buy now (or Out of stock).
- **Reviews**: average rating with a star distribution, review cards, and *Write a review* (shown only to verified buyers).
- **Wishlist**: saved in Supabase; Move to cart; out-of-stock badge.

### Cart, checkout and orders
- **Cart**: quantity stepper limited by stock, colour variant on each line, an Edit mode for bulk delete, a voucher row (coming soon), and a total including delivery.
- **Checkout**: address card (change or add), package card, Cash on delivery (bKash / Nagad / card shown as *coming soon*), and a summary. The total equals subtotal + delivery and matches the saved order.
- **Order confirmation**: order number, item count, total, payment and address, with Track / Continue shopping.
- **My orders**: tabs (All / Processing / Shipped / Delivered / Cancelled), deep links such as `?tab=shipped`, and a per-status action (Track / Write review / Details).
- **Order details**: status banner, items, delivery and payment cards, Track, *Request a return*, and *Need help?*.
- **Tracking**: status card plus a timeline built from shipment events, or derived from the order status when there are none.
- **Return request**: item picker, reason, details, photo placeholder and refund method.

### Account
- **Account tab**: profile header (or a log-in prompt for guests), order shortcuts, and menu rows for wishlist, vouchers, addresses, messages, notifications, help, settings and selling.
- **Edit profile**: name, BD phone, and the email with a *Verified* tag.
- **Address book**: all 8 divisions with their districts, Home / Office / Other labels, default address, select mode for checkout, and swipe to delete.
- **Vouchers**: ticket cards and code entry (try `ZOLLO50`).
- **Notifications**: All / Orders / Promotions tabs, Mark all read, and deep links.
- **Messages and chat**: conversation list with unread badges; chat room with a product context card, bubbles and day chips.
- **Settings**: English / বাংলা choice and notification toggles (both saved on the device), change password, policy links, log out, and delete account (through support).

---

## Architecture

The app is organised **feature-first**, with light Clean Architecture layers inside each feature:

```
presentation/  screens · widgets · providers (Riverpod)   ← UI and state
domain/        models, enums, pure logic (e.g. ProductFilter)
data/          repositories (Supabase / SharedPreferences / fakes)
```

- **Repository pattern with DI**: every repository is exposed through a Riverpod `Provider`, so tests swap in fakes with `overrideWithValue`. Orders, search, chat, vouchers, notifications and returns define an **abstract interface**.
- **Fake repositories for features without a backend yet**: vouchers, notifications, chat (stream based, ready for Supabase Realtime) and returns use `Fake…Repository` classes marked `// TODO(backend)`. Replacing them doesn't touch the UI.
- **Reactive auth**: `currentUserProvider` rebuilds on every Supabase auth event. The wishlist, addresses, orders and review eligibility watch it, so they reload on login and logout.
- **Errors surface immediately**: Riverpod's automatic retry is off (`ProviderScope(retry: …)`), so a failed load shows `ErrorView` with *Try again* instead of spinning.
- **Derived state**: cart count and subtotal, product lookup by id, unread counts, review summaries.
- **Routing**: one `GoRouter` with a `StatefulShellRoute.indexedStack` for the 4 bottom tabs (Home, Categories, Cart, Account). Each tab keeps its own stack.

```
main() → Supabase.initialize → SharedPreferences → ProviderScope(retry off)
      → MaterialApp.router(AppTheme.light, appRouter) → /splash
```

---

## Project Structure

```
lib/
├── main.dart                                   # Bootstrap: Supabase, SharedPreferences, ProviderScope, MyApp
├── core/
│   ├── config/app_config.dart                  # AppConfigRepository + deliveryFeeProvider (app_config table)
│   ├── constants/app_constants.dart            # Fallback delivery fee, URLs, return window, BD divisions → districts
│   ├── debug/style_preview_screen.dart         # Debug-only /style-preview catalogue
│   ├── router/
│   │   ├── app_router.dart                     # All routes + bottom-nav shell
│   │   └── main_scaffold.dart                  # Shell scaffold using AppBottomNav with cart badge
│   ├── theme/
│   │   ├── app_colors.dart                     # Colour tokens
│   │   ├── app_text.dart                       # Manrope text styles + helpers
│   │   ├── app_spacing.dart                    # AppSpacing, AppRadius, AppBorders
│   │   └── app_theme.dart                      # ThemeData built from the tokens
│   ├── utils/
│   │   ├── formatters.dart                     # formatTaka, formatSold, formatDate, formatRelative, …
│   │   └── support.dart                        # contactSupport (mailto), openExternalUrl
│   └── widgets/
│       ├── widgets.dart                        # Barrel export
│       ├── app_bottom_nav.dart                 # Bottom nav + CartBadge
│       ├── app_button.dart                     # primary / outline / deal / danger, small size, loading
│       ├── app_chip.dart                       # Filter / choice chip
│       ├── app_network_image.dart              # CachedNetworkImage with placeholder + broken icon
│       ├── app_text_field.dart                 # Labelled input
│       ├── app_top_bar.dart                    # 64dp app bar with back, subtitle, actions, tabs
│       ├── cart_icon_button.dart               # Cart icon with count badge
│       ├── dashed_border.dart                  # Dashed rect / vertical line painters
│       ├── discount_badge.dart                 # -23% / price drop / out of stock
│       ├── empty_state.dart                    # Icon + title + message + action
│       ├── error_view.dart                     # Error state with Try again + error → text
│       ├── info_card.dart                      # White section card
│       ├── password_field.dart                 # Show / Hide password
│       ├── phone_field.dart                    # +880 prefix, BD validation and formatting
│       ├── price_text.dart                     # Price + struck-through old price
│       ├── product_card.dart                   # Grid product card
│       ├── product_grid.dart                   # Content-sized 2-column sliver grid
│       ├── quantity_stepper.dart               # − value + with stock limits
│       ├── rating_row.dart                     # ★ rating · sold
│       ├── search_field.dart                   # Search input / read-only search button
│       ├── section_header.dart                 # Title + See all
│       ├── shimmer_box.dart                    # Pulsing skeleton, list and grid skeletons
│       ├── status_text.dart                    # Coloured order status
│       └── zollo_logo.dart                     # Wordmark + store mark
└── features/
    ├── splash/presentation/screens/splash_screen.dart
    ├── onboarding/
    │   ├── data/onboarding_repository.dart                      # SharedPreferences flag
    │   └── presentation/
    │       ├── providers/onboarding_provider.dart               # sharedPreferencesProvider, OnboardingController
    │       ├── screens/onboarding_screen.dart
    │       └── widgets/onboarding_page.dart
    ├── auth/
    │   ├── data/repositories/auth_repository.dart               # sign in/up, reset, change password, profile, sign out
    │   ├── domain/auth_validators.dart                          # Validators, strength, friendly errors
    │   ├── domain/providers/auth_provider.dart                  # currentUserProvider, AuthController, User helpers
    │   └── presentation/
    │       ├── screens/login_screen.dart
    │       ├── screens/signup_screen.dart
    │       ├── screens/forgot_password_screen.dart
    │       ├── screens/change_password_screen.dart
    │       └── widgets/auth_widgets.dart                        # AuthScaffold, rules checklist, strength bar, links
    ├── home/presentation/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── home_header.dart                                 # Deliver-to, bell, search
    │       ├── promo_banner.dart                                # Campaign carousel
    │       ├── category_row.dart                                # 4 categories + All
    │       ├── flash_sale_section.dart                          # Countdown + stock bars
    │       └── just_for_you_section.dart
    ├── categories/
    │   ├── data/category_repository.dart                        # Active categories from Supabase
    │   ├── domain/category.dart                                 # Model + icon mapping
    │   └── presentation/
    │       ├── providers/categories_provider.dart               # categoriesProvider, productsByCategoryProvider
    │       └── screens/categories_screen.dart                   # Rail + panel (tab 2)
    ├── products/
    │   ├── data/repositories/product_repository.dart            # Active products + category name
    │   ├── domain/models/product.dart                           # Product (+ categoryId, originalPrice, soldCount)
    │   ├── domain/product_filter.dart                           # Search / sort / filter logic
    │   └── presentation/
    │       ├── providers/products_provider.dart                 # productsProvider, productLookupProvider
    │       ├── screens/product_list_screen.dart
    │       ├── screens/product_details_screen.dart
    │       └── widgets/product_filter_sheet.dart                # Price range + category sheet
    ├── search/
    │   ├── data/search_repository.dart                          # Recent searches (prefs) + trending
    │   └── presentation/
    │       ├── providers/search_providers.dart
    │       └── screens/search_screen.dart
    ├── reviews/
    │   ├── data/review_repository.dart                          # Reviews; delivered-order check, RLS error mapping
    │   ├── domain/review.dart
    │   ├── domain/review_summary.dart                           # Average + distribution
    │   ├── providers/review_providers.dart
    │   └── presentation/
    │       ├── screens/product_reviews_screen.dart
    │       ├── screens/write_review_screen.dart
    │       └── widgets/rating_stars.dart
    ├── wishlist/
    │   ├── data/wishlist_repository.dart
    │   ├── domain/wishlist_item.dart
    │   └── presentation/
    │       ├── providers/wishlist_provider.dart
    │       ├── screens/wishlist_screen.dart
    │       └── widgets/wishlist_button.dart
    ├── cart/
    │   ├── domain/models/cart_item.dart                         # CartItem (+ variant)
    │   └── presentation/
    │       ├── providers/cart_provider.dart                     # CartController, count, subtotal
    │       ├── screens/cart_screen.dart
    │       └── widgets/cart_item_tile.dart
    ├── checkout/
    │   └── screens/checkout_screen.dart                         # Builds a PlaceOrderRequest, idempotency key
    ├── orders/
    │   ├── data/repositories/order_repository.dart              # Interface
    │   ├── data/repositories/supabase_order_repository.dart     # place_order() / cancel_order() RPCs
    │   ├── domain/models/order_model.dart                       # OrderStatus, OrderItem, OrderModel
    │   ├── domain/models/payment_method.dart                    # PaymentMethod + DB values
    │   ├── domain/models/place_order_request.dart               # PlaceOrderRequest, PlaceOrderLine
    │   ├── domain/order_exception.dart                          # DB error codes → friendly messages
    │   └── presentation/
    │       ├── providers/order_provider.dart                    # history, details, PlaceOrderController
    │       ├── screens/order_confirmation_screen.dart
    │       ├── screens/order_history_screen.dart                # Tabs + OrderCard
    │       ├── screens/order_details_screen.dart
    │       └── widgets/order_thumbnail.dart
    ├── tracking/
    │   ├── data/tracking_repository.dart
    │   ├── domain/tracking_event_model.dart                     # Shipment, TrackingEvent
    │   ├── providers/tracking_provider.dart
    │   └── presentation/
    │       ├── screens/tracking_screen.dart
    │       └── widgets/tracking_timeline.dart                   # TimelineStep (from events or status)
    ├── returns/
    │   ├── data/return_repository.dart                          # Interface + fake (TODO backend)
    │   ├── domain/return_request.dart
    │   └── presentation/
    │       ├── providers/return_providers.dart
    │       └── screens/return_request_screen.dart
    ├── address/
    │   ├── data/address_repository.dart
    │   ├── domain/address_model.dart                            # + displayAddress, shortArea
    │   └── presentation/
    │       ├── providers/address_provider.dart
    │       ├── screens/address_list_screen.dart
    │       ├── screens/add_edit_address_screen.dart
    │       └── widgets/address_card.dart
    ├── profile/presentation/screens/
    │   ├── profile_screen.dart                                  # Account tab
    │   └── edit_profile_screen.dart
    ├── vouchers/
    │   ├── data/voucher_repository.dart                         # Interface + fake (TODO backend)
    │   ├── domain/voucher.dart
    │   └── presentation/
    │       ├── providers/voucher_providers.dart
    │       └── screens/vouchers_screen.dart
    ├── notifications/
    │   ├── data/notification_repository.dart                    # Interface + fake (TODO backend)
    │   ├── domain/app_notification.dart
    │   └── presentation/
    │       ├── providers/notification_providers.dart            # + unread count
    │       └── screens/notifications_screen.dart
    ├── chat/
    │   ├── data/chat_repository.dart                            # Stream interface + fake (TODO backend)
    │   ├── domain/chat_models.dart                              # Conversation, ChatMessage
    │   └── presentation/
    │       ├── providers/chat_providers.dart
    │       ├── screens/messages_screen.dart
    │       └── screens/chat_room_screen.dart
    └── settings/
        ├── data/settings_repository.dart                        # Locale + notification prefs
        └── presentation/
            ├── providers/settings_providers.dart
            └── screens/settings_screen.dart

assets/fonts/Manrope/                       # Manrope[wght].ttf + OFL licence
docs/ui_build_plan.md                       # Design tokens, rules and per-screen spec

test/
├── support/test_helpers.dart               # Fakes (auth, wishlist), sample data, pumpRoutes, tall viewport
├── core/                                   # formatters, shared widgets, router flow
├── features/<feature>/…                    # Screen + provider tests per feature
├── layout_scaling_test.dart                # All 30 screens at 360dp and 1.3× text
├── e2e_marketplace_test.dart, workflow_test.dart, product_test.dart, widget_test.dart
```

---

## Navigation & Routes

| Route | Screen | Notes |
| --- | --- | --- |
| `/splash`, `/onboarding` | Splash, Onboarding | Start-up |
| `/login`, `/signup`, `/forgot-password` | Auth | |
| `/home` · `/categories` · `/cart` · `/account` | Bottom-nav tabs | `StatefulShellRoute` |
| `/search` | Search | |
| `/products?category=<id>&q=<text>` | Product list | |
| `/product-details` | Product details | `extra: Product` |
| `/product-reviews`, `/write-review` | Reviews | `extra: Product` |
| `/checkout` | Checkout | `extra: {subtotal, deliveryCharge}` |
| `/order-confirmation` | Order placed | `extra: OrderModel` |
| `/order-history?tab=<all\|processing\|shipped\|delivered\|cancelled>` | My orders | |
| `/order-details/:orderId`, `/tracking/:orderId` | Order details, Tracking | |
| `/return-request` | Return request | `extra: OrderModel` |
| `/wishlist`, `/edit-profile` | Account screens | |
| `/addresses?select=true`, `/add-address`, `/edit-address` | Address book | `/edit-address` takes `extra: Address` |
| `/vouchers`, `/notifications` | Vouchers, Notifications | |
| `/messages`, `/messages/:conversationId` | Messages, Chat room | |
| `/settings`, `/settings/change-password` | Settings | |
| `/style-preview` | Design system catalogue | Debug builds only |

---

## Backend (Supabase)

The schema lives in [`supabase/migrations/`](supabase/migrations/): `20261030000100_hardening.sql` (constraints, RLS on every table, triggers) and `20261030000200_variants_payments_place_order.sql` (variants, stock reservations, payments and the order functions). Run them in the Supabase SQL editor in that order.

| Table / function | Used by |
| --- | --- |
| `products` (+ `categories` join; `compare_at_price`, `rating`, `rating_count`) | ProductRepository |
| `categories` | CategoryRepository |
| `wishlist` | WishlistRepository |
| `addresses`, `set_default_address()` | AddressRepository |
| `place_order()`, `cancel_order()`, `orders` + `order_items` (read) | SupabaseOrderRepository |
| `order_items` + `orders` (delivered check) | ReviewRepository |
| `shipments`, `tracking_events` (`occurred_at`) | TrackingRepository |
| `product_reviews` (insert allowed by RLS only after delivery) | ReviewRepository |
| `app_config` (`delivery_fee`) | AppConfigRepository |

Orders are never inserted by the app: `place_order()` reads prices and stock from the database, reserves stock, records a payment row and is idempotent per checkout attempt. Its error codes (`OUT_OF_STOCK`, `ADDRESS_NOT_FOUND`, …) are shown as friendly messages.

Auth uses Supabase email/password. `full_name` and `phone` are stored in user metadata. Vouchers, notifications, chat and returns run on fake repositories until their tables exist.

---

## Getting Started

```bash
flutter pub get

# Uses the default Supabase project in main.dart
flutter run

# Or your own project
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon-or-publishable-key>
```

In a debug build, open `/style-preview` to check the design system on a device.

---

## Testing

```bash
flutter analyze   # no issues
flutter test      # 141 tests
```

The tests cover the formatters, shared widgets, router start-up flow, and each feature's screens, which run with faked repositories (auth, wishlist, orders, reviews, addresses, search, chat, vouchers, notifications, settings, returns). A layout test renders every screen at 360dp width with 1.3× text and fails on any overflow.

---

## Known Limitations / Roadmap

- **The two migrations must be run** before checkout, default addresses and the delivery-fee config work against the live project. After that, run the LOCKDOWN block at the end of migration 2 to drop the temporary insert policies.
- Discount badges need `compare_at_price` set on products; there is no `sold_count` column, so sold counts don't show. Every current product has `category_id = null`, so the category screens show empty states.
- Colour options are hardcoded (Black / White / Navy). Products have a single image.
- Payments: only cash on delivery works. bKash, Nagad and cards are *coming soon*. Vouchers can't be applied at checkout yet.
- Vouchers, notifications, chat and returns use fake data (`TODO(backend)`).
- The language choice is saved but there are no translations yet.
- The cart lives in memory and is not synced to Supabase (`cart_items`), and it sends product ids, so `place_order()` uses each product's default variant.
- Account deletion goes through support; there is no delete endpoint yet.
