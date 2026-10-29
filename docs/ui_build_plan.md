# zollo — UI build plan for Claude Code

This file is the single source of truth for rebuilding zollo's UI. It holds:

1. **Shared rules and design tokens** (Part A). Every prompt depends on them.
2. **One copy-paste prompt per step** (Part B). Run them one at a time, in order.
3. **A screen spec for every page** (Part C). Each prompt points at one of these.

## How to use it

1. Save this file in the repo as `docs/ui_build_plan.md` and commit it.
2. Open Claude Code in the repo root.
3. Paste **Prompt 0** first. When it finishes, run the app, check it, and commit.
4. Paste the next prompt. Do one prompt per session or per commit, so a bad step is easy to undo.
5. If a screen looks wrong, tell Claude Code what is off and point it back at the spec in Part C.

---

# Part A — Shared rules (Claude Code must follow these in every step)

## A1. Project facts

- Flutter, Material 3. State management: **flutter_riverpod**. Routing: **go_router** with `StatefulShellRoute.indexedStack` (4 tabs). Backend: **supabase_flutter**.
- The code is feature-first: `lib/features/<feature>/{data,domain,presentation}`. Shared code lives in `lib/core/`.
- Repositories and providers already exist for auth, products, cart, wishlist, address, orders, tracking and reviews. **Reuse them. Do not rewrite data logic** unless a prompt explicitly asks for it.

## A2. Rules for every step

1. Read `docs/ui_build_plan.md` (Part A, plus the Part C section the prompt names) before you write code.
2. Use only the tokens in A3–A5 (`AppColors`, `AppText`, `AppSpacing`, `AppRadius`). **No hex colours, font sizes or magic paddings inside screen files.**
3. Build screens from the shared widgets in `lib/core/widgets/` (A6). If a screen needs a new reusable piece, add it there, not inside the screen.
4. Every screen handles **loading, empty and error** states. Use `AsyncValue.when`, `ShimmerBox` for loading, `EmptyState` for empty and `ErrorView` (with a Retry button) for errors.
5. Accessibility: tap targets at least 48×48, a `tooltip` or `Semantics` label on every icon-only button, and text contrast of at least 4.5:1 (the tokens already meet this).
6. Text scaling: no fixed heights on anything that contains text, except buttons and inputs (they have fixed heights in the spec). Test with the system font size set to 1.3×.
7. Images: use `CachedNetworkImage` (already in pubspec) with an `AppColors.placeholder` box while loading and a broken-image icon on error.
8. Money: always use the `formatTaka()` helper from A5 (`৳2,450`), never string concatenation.
9. Don't add new packages unless the prompt lists them. If you think one is needed, stop and ask.
10. When you finish a step:
    - Run `flutter analyze` and fix every warning you introduced.
    - Run `flutter test` and keep all existing tests passing.
    - Add at least one widget test per new screen: it renders and its main button works.
    - End with a short list of the files you created or changed, and anything left as a TODO.

## A3. Colours (`lib/core/theme/app_colors.dart`)

| Token | Hex | Use |
| --- | --- | --- |
| `primary` | `#8A1C5E` | Main buttons, links, active tab, prices, selected states |
| `primaryDark` | `#6B1247` | Pressed / hover state of primary |
| `primaryOnDark` | `#741650` | Icon-button circles on top of a primary background |
| `primaryTint` | `#F8E7F0` | Selected chip fill, icon tiles, success circles |
| `onPrimaryMuted` | `#F4D6E5` | Secondary text placed on a primary background |
| `accent` | `#F5B301` | Deal / sale buttons, flash-sale stock bars, campaign labels |
| `onAccent` | `#1B1A16` | Text on accent |
| `deep` | `#2A1023` | Campaign banners, countdown boxes |
| `ink` | `#1F1A1E` | Main text and icons |
| `inkSoft` | `#43393F` | Body text in dense info blocks |
| `muted` | `#6B6168` | Secondary text, inactive tab |
| `hint` | `#8E858B` | Placeholders, timestamps |
| `background` | `#FAF7F5` | Page background behind cards |
| `surface` | `#FFFFFF` | Cards, app bars, bottom bars, sheets |
| `surfaceAlt` | `#F4EFF2` | Filled search fields, neutral chips, side rail |
| `placeholder` | `#EFE9EC` | Image placeholders |
| `border` | `#D6CDD2` | Input borders, outline buttons, unselected chips |
| `divider` | `#EAE3E7` | Lines, app-bar bottom borders, card borders |
| `switchOff` | `#B9AFB5` | Switch track when off, empty stars |
| `discountBg` | `#FDE7C2` | Discount badge background |
| `discountText` | `#7A4A00` | Discount badge text |
| `star` | `#E9A100` | Rating star fill |
| `warning` | `#9A5B00` | Awaiting payment, expiring vouchers |
| `error` | `#9B1C1C` | Out of stock, errors, log out |
| `errorBg` | `#FBE2E2` | Out-of-stock badge background |

Build the `ColorScheme` in `AppTheme.light` from these:

- `primary`, `onPrimary: white`
- `secondary: accent`, `onSecondary: onAccent`
- `surface`, `onSurface: ink`
- `error`
- `outline: border`, `outlineVariant: divider`

Set `scaffoldBackgroundColor: background`. Remove the old `#5B4BDB` seed colour and the `#006B54` nav colour everywhere.

## A4. Typography (`lib/core/theme/app_text.dart`) — font: Manrope

Bundle Manrope: put the variable font `Manrope[wght].ttf` in `assets/fonts/Manrope/` and declare it in `pubspec.yaml`. If bundling isn't possible, use the `google_fonts` package instead; that is the one exception to rule A2.9.

| Style | Size / weight | Use |
| --- | --- | --- |
| `display` | 28 / w800 | Auth page titles |
| `headline` | 26 / w800 | Success titles, product price |
| `title` | 18 / w800 | App-bar titles |
| `section` | 16 / w800 | Section headers ("Flash Sale", "Just for you") |
| `bodyStrong` | 14 / w700 | Names, row titles |
| `body` | 15 / w500 | Paragraphs (line height 1.5) |
| `bodySmall` | 13 / w600 | Product names in cards, menu rows |
| `label` | 13 / w700 | Form labels, chip text |
| `caption` | 12 / w500 | Meta text: "3.4k sold · Dhaka", timestamps |
| `micro` | 11 / w600 | Bottom-nav labels, badges |
| `price` | 16 / w800, primary | Card prices |
| `priceOld` | 11–12 / w500, muted, line-through | Old price |

Wire these into `ThemeData.textTheme` as well, so plain `Text` widgets get Manrope.

## A5. Spacing, shape, helpers

- **`AppSpacing`:** `xs 4`, `s 8`, `m 12`, `l 16`, `xl 24`, `xxl 32`.
  - Screen side padding is 16; padding inside cards is 12–14; the gap between cards is 10–12.
- **`AppRadius`:** `button 12`, `input 12`, `card 14`, `banner 16`, `tile 10`, `chip 999` (fully round), `badge 6`.
- **Borders:** 1px `border` on inputs, outline buttons and unselected chips; 1.5px `primary` on selected chips and outline primary buttons; 1px `divider` on cards that sit on a white page.
- **Shadows:** none. The style is flat. Separate things with the `background` colour and `divider` lines instead.
- **Icons:** Material *outlined* icons. 22 in app bars and the bottom nav, 18–20 inline.
- **Helpers** (`lib/core/utils/formatters.dart`):
  - `formatTaka(num)` → `৳2,450`, with no decimals when the value is whole.
  - `formatSold(int)` → `3.4k sold`.
  - `formatDate(DateTime)` → `13 Oct`.
- **Constants:** add `lib/core/constants/app_constants.dart` with `deliveryFee = 60`. Use it everywhere a delivery fee appears (cart, router, checkout) and delete the hardcoded 120 and the hardcoded −100 in checkout.

## A6. Shared widgets (`lib/core/widgets/`)

| Widget | Spec |
| --- | --- |
| `AppButton` | Variants: `primary` (primary fill, white text), `outline` (1.5px primary border, primary text), `deal` (accent fill, onAccent text), `danger` (1.5px error border, error text). Height 52, radius 12, text 15–16 / w800, full width by default. Has a `loading` flag (spinner, disabled) and an optional leading icon. A `small` size is 40 high, 13 / w800 text. |
| `AppTextField` | A label above (13 / w700, 6 gap), 52 high, radius 12, 1px border, 1.5px primary border when focused, 14 horizontal padding, `hint` placeholder. Error text below in `error`. |
| `PasswordField` | `AppTextField` plus a Show / Hide text button (13 / w700, primary) inside the right edge. |
| `PhoneField` | `AppTextField` with a grey `+880` prefix block (`surfaceAlt`, 15 / w700) and validation `^1[3-9]\d{8}$` (11 digits with the leading 0 also accepted). |
| `SearchField` | 44–46 high, radius 12, `surfaceAlt` fill (white on a primary header), search icon on the left and a clear button when there is text. Has a `readOnly` + `onTap` mode for fake search bars that open the search screen. |
| `AppChip` | 34 high, fully round, 12 horizontal padding. Selected: `primaryTint` fill, 1.5px primary border, primary text w700. Unselected: white, 1px border, ink text w600. |
| `DiscountBadge` | `discountBg` fill, `discountText` text 11–12 / w800, radius 6, padding 2×6, text like `-23%`. Variants: `priceDrop` (same colours) and `outOfStock` (`errorBg` / `error`). |
| `PriceText` | Price (`price` style) plus an optional old price (`priceOld`) in a baseline-aligned row, gap 6. |
| `RatingRow` | Star icon 12–14 in `star`, then rating, `·`, sold count, in caption / muted. |
| `ProductCard` | White, radius 14, clips its children. Photo 150 high (cover) with a `DiscountBadge` 8 in from the top-right and an optional wishlist heart top-left. Below, padding 10, gap 4: name (`bodySmall`, max 2 lines, ellipsis), `PriceText`, `RatingRow`. The whole card is tappable and opens product details. |
| `QuantityStepper` | Bordered box (1px border, radius 10): a 36×36 `−` button, the value 32 wide (14 / w700), a 36×36 `+` button. Disables `−` at 1 and `+` at stock. |
| `SectionHeader` | Title (`section`) on the left, an optional "See all" text button (13 / w700, primary) on the right. |
| `AppTopBar` | White, 64 high, 1px divider at the bottom, a 44×44 back button, title (`title`), optional trailing actions. Implement as a `PreferredSizeWidget`. |
| `InfoCard` | White, radius 14, padding 14 — the standard container for sections on grey pages. |
| `EmptyState` | Centred: an icon in a 64 `primaryTint` circle, title (`bodyStrong`), message (caption / muted), optional `AppButton`. |
| `ErrorView` | Like `EmptyState` with an error icon, the message, and a "Try again" outline button. |
| `ShimmerBox` | A simple animated `placeholder`-coloured box for loading skeletons (no package; use an `AnimatedOpacity` pulse). |
| `StatusText` | Order-status label coloured by status: pending → `warning`, confirmed / processing / shipped → `primary`, delivered → `inkSoft`, cancelled → `error`. Text 13 / w800. |
| `AppBottomNav` | Used by `MainScaffold`. White, 64 high plus the safe area, 1px divider on top, 4 items (Home, Categories, Cart, Account), outlined icons 22. Active: primary icon and label 11 / w700. Inactive: muted, 11 / w600. The Cart icon shows a badge (primary circle, white 10 / w800 count) when the cart isn't empty. |

---

# Part B — The prompts

Paste each prompt into Claude Code exactly as written. Wait for it to finish, check the app, and commit before you paste the next one.

## Phase 1 — Foundation

### Prompt 0 · Design system

```
Read docs/ui_build_plan.md, Part A, completely.

Implement the design system for zollo:
1. Create lib/core/theme/app_colors.dart (A3), lib/core/theme/app_text.dart (A4)
   and lib/core/theme/app_spacing.dart with AppSpacing + AppRadius (A5).
2. Rewrite lib/core/theme/app_theme.dart so AppTheme.light uses these tokens:
   ColorScheme as described in A3, Manrope text theme, scaffold background,
   AppBarTheme (white, no elevation, ink icons, title style), InputDecorationTheme,
   FilledButton/OutlinedButton/TextButton themes, ChipTheme, CheckboxTheme, RadioTheme,
   SwitchTheme, DividerTheme, BottomSheetTheme, SnackBarTheme — all from the tokens.
3. Bundle the Manrope font as described in A4.
4. Add lib/core/utils/formatters.dart and lib/core/constants/app_constants.dart (A5),
   replace every delivery-fee literal (60 / 120) with AppConstants.deliveryFee and
   remove the hardcoded -100 from the checkout total.
5. Create every widget in A6 under lib/core/widgets/, each in its own file, plus a
   widgets.dart barrel export.
6. Restyle MainScaffold to use AppBottomNav, with the cart badge driven by
   cartItemCountProvider.
7. Update ZolloLogo: a 'zollo' wordmark (w800, letter-spacing -1) in primary, or white
   when placed on primary, with an optional rounded-square store icon mark.
8. Add a debug-only route /style-preview that shows every colour, text style and widget
   on one scrollable screen, so I can check them on a device.
Do not change any screen layouts yet. Follow the rules in A2 and finish with the A2.10 checks.
```

## Phase 2 — Screens that already exist in the app (restyle, keep their logic)

### Prompt 1 · Splash and onboarding

```
Read docs/ui_build_plan.md Part A and Part C sections C1 and C2.
Restyle SplashScreen and OnboardingScreen to match the spec exactly.
Keep the existing navigation logic (1.5 s delay; onboarding / login / home decision;
OnboardingController and its SharedPreferences flag) unchanged.
Use the shared widgets from lib/core/widgets. Follow A2 and finish with the A2.10 checks.
```

### Prompt 2 · Login and sign-up

```
Read docs/ui_build_plan.md Part A and Part C sections C3 and C4.
Restyle LoginScreen and SignupScreen to the spec. Keep AuthRepository and AuthController.
- Replace AuthFormField with AppTextField / PasswordField / PhoneField.
- Add inline validation: email format, password at least 8 characters,
  BD phone format (optional field), terms checkbox required on sign-up.
- Show Supabase AuthException messages in a SnackBar in plain language.
- Sign-up: save phone into user metadata together with full_name.
- Add the 'Continue as guest' link (goes to /home) and the 'Forgot password?' link
  (goes to /forgot-password; that screen comes in Prompt 3).
Follow A2 and finish with the A2.10 checks.
```

### Prompt 3 · Forgot password and change password

```
Read docs/ui_build_plan.md Part A and Part C sections C5 and C27.
1. Create ForgotPasswordScreen at /forgot-password: calls
   supabase.auth.resetPasswordForEmail(email); on success switches to the
   'Check your inbox' state described in C5.
2. Create ChangePasswordScreen at /settings/change-password: re-authenticates with
   signInWithPassword(current email, current password), then calls
   supabase.auth.updateUser(UserAttributes(password: newPassword)).
   Include the live password-rules checklist from C5/C27.
Put both under lib/features/auth/presentation/screens/. Add the methods to AuthRepository.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 4 · Home

```
Read docs/ui_build_plan.md Part A and Part C section C6.
Restyle HomeScreen and its widgets (HomeHeader, PromoBanner, CategoryRow,
FlashSaleSection, JustForYouSection) to the spec.
- The header shows 'Deliver to <area>, <district>' from defaultAddressProvider,
  or 'Add a delivery address' (tappable, opens /add-address) when there is none.
- The search bar is a read-only SearchField that opens /search (route added in Prompt 12;
  until then make it open /categories).
- Category tiles come from the categories table: add a CategoryRepository + categoriesProvider
  (id, name, image_url, only is_active, ordered by name). Tapping a tile opens the product
  list filtered by that category.
- Flash sale and Just for you use productsProvider. Use ProductCard for the grid.
- Pull-to-refresh invalidates productsProvider and categoriesProvider.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 5 · Product list and categories browser

```
Read docs/ui_build_plan.md Part A and Part C sections C7 and C8.
1. Create CategoriesScreen (C8) and make it the content of bottom-nav tab 2 (/categories).
2. Move ProductListScreen to a pushed route /products with optional query params
   category (id) and q (search text), restyled to C7.
3. Make search and the filter chips actually work, client-side, on productsProvider data:
   text search on name, 'Price' toggles low-to-high / high-to-low, '4★ & up' filters by rating,
   category filter from the query param. Show the live result count.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 6 · Product details and reviews

```
Read docs/ui_build_plan.md Part A and Part C sections C9, C20 and C21.
1. Restyle ProductDetailsScreen to C9: image header with overlay buttons, price section,
   colour chips (keep the current hardcoded colours for now), delivery info section,
   reviews summary, sticky bottom bar. Keep the stock-aware add-to-cart logic.
   'Buy now' adds to cart and opens /cart.
2. Restyle ProductReviewsScreen to C20 (average, distribution bars, review cards) and give
   it a route, /product-reviews (extra: Product); it has none yet. Link 'See all' to it.
3. Create WriteReviewScreen at /write-review (extra: Product) per C21, using the existing
   ReviewRepository.submitReview. Show the 'Write a review' button on product details and
   in order history only when canUserReviewProvider is true.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 7 · Cart

```
Read docs/ui_build_plan.md Part A and Part C section C10.
Restyle CartScreen and CartItemTile to the spec, using QuantityStepper and the summary bar.
Keep CartController and its providers. Add the empty state. Use AppConstants.deliveryFee.
The voucher row is visual only for now: tapping it shows a 'Vouchers are coming soon' SnackBar.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 8 · Checkout and order confirmation

```
Read docs/ui_build_plan.md Part A and Part C sections C11 and C12.
1. Restyle CheckoutScreen to C11. Payment rows: Cash on delivery is enabled and selected
   by default; bKash, Nagad and Card are shown disabled with a 'Coming soon' tag.
   The total shown must equal subtotal + AppConstants.deliveryFee and must match what is saved.
2. Restyle OrderConfirmationScreen to C12.
Keep PlaceOrderController and the address-selection flow (/addresses?select=true).
Follow A2 and finish with the A2.10 checks.
```

### Prompt 9 · Orders, order details and tracking

```
Read docs/ui_build_plan.md Part A and Part C sections C13, C14 and C15.
1. Restyle OrderHistoryScreen to C13 with the status tab bar (filter client-side).
2. Restyle OrderDetailsScreen to C14.
3. Restyle TrackingScreen and TrackingTimeline to C15. If an order has no shipment or
   events yet, build the timeline from the order status instead (see C15).
Follow A2 and finish with the A2.10 checks.
```

### Prompt 10 · Wishlist

```
Read docs/ui_build_plan.md Part A and Part C section C16.
Restyle WishlistScreen and WishlistButton to the spec. Add 'Move to cart'
(adds to cart, then removes from the wishlist) and the empty state.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 11 · Account, edit profile and addresses

```
Read docs/ui_build_plan.md Part A and Part C sections C17, C18, C22 and C23.
1. Restyle ProfileScreen to C17. Menu rows for screens that don't exist yet go to the
   routes created in Phase 3; until then they show a 'Coming soon' SnackBar.
2. Restyle EditProfileScreen to C18.
3. Restyle AddressListScreen (both normal and select mode) to C22 and
   AddEditAddressScreen to C23, with BD phone validation.
Follow A2 and finish with the A2.10 checks.
```

## Phase 3 — New screens from the design

These screens have no backend yet (except Settings). For each one, create the feature folder with a domain model, an abstract repository, a **`Fake…Repository` with realistic sample data** and a provider, so the real Supabase repository can replace it later without touching the UI. Mark each fake with `// TODO(backend): replace with Supabase implementation`.

### Prompt 12 · Search

```
Read docs/ui_build_plan.md Part A and Part C section C19.
Create the search feature at /search per C19. Suggestions come from filtering productsProvider
by name client-side (debounce 300 ms). Recent searches are stored in SharedPreferences
(max 8, newest first, with Clear). 'Trending' is a static list in the fake repository.
Submitting a search opens /products?q=<text>. Point the Home search bar at /search.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 13 · Vouchers and notifications

```
Read docs/ui_build_plan.md Part A and Part C sections C24 and C25, and the Phase 3 rule
above (fake repositories).
Create lib/features/vouchers (VouchersScreen at /vouchers) and lib/features/notifications
(NotificationsScreen at /notifications) with fake repositories and sample data.
Wire the Home bell icon and the Account menu rows to them. 'Mark all read' and tab
filtering work on the local state.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 14 · Messages and chat

```
Read docs/ui_build_plan.md Part A and Part C sections C26a and C26b, and the Phase 3 rule.
Create lib/features/chat with MessagesScreen (/messages) and ChatRoomScreen
(/messages/:conversationId). Use a fake repository that exposes
Stream<List<ChatMessage>> watchMessages(conversationId) and sendMessage(), so a later
Supabase Realtime version can replace it. Sending a message appends it immediately.
Wire 'Chat with seller' buttons (product details, tracking) and the Account menu row.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 15 · Settings and return request

```
Read docs/ui_build_plan.md Part A and Part C sections C27 and C28.
1. Create SettingsScreen at /settings (C27):
   - Language switch (English / বাংলা) saved to SharedPreferences through a localeProvider
     (no translations yet; just store the choice).
   - Notification toggles saved to SharedPreferences.
   - Rows: Change password (/settings/change-password), Privacy policy and Terms
     (open URLs from AppConstants).
   - Log out (AppButton danger) and Delete account, which opens a confirm dialog and then a
     'Contact support to delete your account' message for now.
   Move Log out from the Account screen to Settings.
2. Create ReturnRequestScreen at /return-request (extra: OrderModel) per C28. Submitting shows
   a success SnackBar and pops (TODO(backend)). Show 'Request a return' on delivered orders
   in order details.
Follow A2 and finish with the A2.10 checks.
```

### Prompt 16 · Final polish pass

```
Read docs/ui_build_plan.md Part A.
Go through every screen in lib/features and check it against Part A:
- no hardcoded colours, font sizes or magic numbers in screen files
- loading / empty / error states present
- tooltips on icon-only buttons, 48 dp targets
- works at 1.3× text scale and on a 360 dp wide screen without overflow
- every route in app_router.dart is reachable and the back button behaves
Fix what you find, delete unused files (empty stubs, supabase_test_screen from release builds)
and remove the unused dio dependency if nothing uses it.
Finish with the A2.10 checks and a short report of what changed.
```

---

# Part C — Screen specs

The canvas uses a 390×844 phone. Sizes are in logical pixels (dp). "Card" means `InfoCard` (white, radius 14, padding 14) on the `background` page colour unless stated otherwise.

### C1. Splash (`/splash`)

- Full-screen `primary` background, safe area.
- Centred column, gap 14:
  - a white 88×88 rounded square (radius 26) with a store outline icon (46, `primary`)
  - "zollo" 40 / w800, letter-spacing −1, white
  - the tagline "Everything you need, delivered across Bangladesh", 15, `onPrimaryMuted`
- Bottom: a small white `CircularProgressIndicator` (strokeWidth 2) above "English · বাংলা" (12, `onPrimaryMuted`).
- Logic stays as it is (1.5 s delay, then route).

### C2. Onboarding (`/onboarding`)

- White page, padding 24 at the sides, 16 at the top, 40 at the bottom.
- Top-right: a "Skip" text button (14 / w700, primary).
- Middle, gap 28:
  - an illustration panel, full width, 300 high, radius 28, `primaryTint`, with a large outline icon (120, `primary`); one icon per slide: shopping bag, payment card, delivery truck
  - title (26 / w800)
  - body (15, `muted`, line height 1.5)
  - page dots: active 22×6 `primary`, inactive 6×6 `border`, gap 6, radius 3
- Slides:
  1. "Millions of products from trusted sellers" / "Fashion, electronics, groceries and more, all in one app."
  2. "Pay the way you like" / "bKash, Nagad, cards, or cash on delivery. Your payment is protected."
  3. "Track every order to your door" / "Live updates from packing to delivery, and easy 7-day returns."
- Bottom: `AppButton.primary` "Next", which becomes "Get started" on the last slide (it completes onboarding and opens /login). A swipe changes the slide.

### C3. Log in (`/login`)

- White page, padding 24, gap 24.
- A back button 44 only when the screen can pop.
- Title "Welcome back" (`display`) and subtitle "Log in to track orders and check out faster." (15, `muted`).
- `AppTextField` "Email" and `PasswordField` "Password".
- A row: a "Keep me logged in" checkbox (13; Supabase already keeps the session, so this is visual) on the left, "Forgot password?" (13 / w700, primary) on the right.
- `AppButton.primary` "Log in" (loading while signing in).
- A divider row with "or continue with" (13, `muted`) between two lines, then 2 equal outline buttons "Google" and "Facebook", 50 high. They stay hidden until OAuth is set up; put them behind a `bool showSocialLogin = false` constant.
- Bottom (pushed down with a Spacer):
  - "New to zollo? **Create an account**" (14, `muted`; the link is w800 primary)
  - below it "Continue as guest" (14 / w700, `muted`) → /home

### C4. Sign up (`/signup`)

- Same frame as C3, gap 20.
- Title "Create your account" and subtitle "Shop, track orders and save your favourites."
- Fields, gap 14:
  - Full name
  - Email
  - Phone (`PhoneField`, optional)
  - Password (`PasswordField`)
- A password strength bar: 4 segments, 4 high, radius 2, gap 6. Filled segments are `primary`, the rest `divider`; fill 1–4 by length and character mix.
- A terms checkbox: "I agree to the **Terms of use** and **Privacy policy**" (13, `muted`, the links primary w700). It is required.
- `AppButton.primary` "Create account".
- Bottom: "Already have an account? **Log in**".
- If Supabase requires email confirmation, show a success state instead of the form: a mail icon in a `primaryTint` circle, "Check your email", "We sent a confirmation link to <email>.", and a "Back to log in" button.

### C5. Forgot password (`/forgot-password`) and the password rules

- White page, padding 24, gap 24; a back button.
- A 64×64 `primaryTint` tile (radius 20) with a lock icon (30, `primary`).
- Title "Forgot your password?" (`display`) and body "Enter the email on your account. We'll send you a link to reset it." (15, `muted`).
- `AppTextField` "Email" and `AppButton.primary` "Send reset link".
- Bottom: "Remembered it? **Back to log in**".
- Success state: the same layout with a mail icon, the title "Check your inbox", the body "We sent a reset link to <email>.", and a "Back to log in" button.
- **Password rules checklist** (used in C27, and in sign-up if you like): rows, 13, `muted`, gap 6:
  - "At least 8 characters"
  - "One number"
  - "One uppercase letter"
  - a met rule shows a 16 check icon in `primary`; an unmet rule shows a 16 empty circle in `hint`

### C6. Home (`/home`, tab 1)

- **Header**, `primary` background, padding 20 top, 16 sides and bottom, gap 14:
  - Row 1: on the left a column of "zollo" (22 / w800, white, letter-spacing −0.5) and "Deliver to Dhanmondi, Dhaka" (12, `onPrimaryMuted`); on the right a 44 circle in `primaryOnDark` with a white bell icon → /notifications.
  - Row 2: a white read-only `SearchField` 46 high with the placeholder "Search products, brands and shops".
- **Body** on `background`, scrollable, padding top 16, gap 20:
  1. **Campaign banner** (PageView, 16 side margin): 140 high, radius 16, `deep` background, padding 20.
     - Top: the label "11.11 MEGA SALE" (12 / w700, `accent`, letter-spacing 1), then the title (24 / w800, white, max 2 lines).
     - Bottom-left: a pill button (accent fill, onAccent 13 / w700, padding 8×14).
     - Under the banner, dots: active 18×6 `primary`, inactive 6×6 `border`.
     - Banner content is a static list for now.
  2. **Category row**: a 5-column grid, gap 8. Each item is a 52×52 white tile (radius 16) with a 24 outlined icon in `primary`, and below it the name (11 / w600, 1 line). It shows the first 5 categories; the last tile can be "All" → /categories.
  3. **Flash sale card** (`InfoCard`, radius 16, 16 side margin), gap 12:
     - Header row: "Flash Sale" (16 / w800) + a countdown of 3 boxes HH MM SS (`deep` fill, white 12 / w700, padding 2×5, radius 4, gap 3), with "See all" on the right.
     - Below, a 3-column grid of mini items, gap 10: photo 96 high (radius 10), price (15 / w800 primary), old price (11, `muted`, line-through), and a stock bar 6 high, radius 3 (track `discountBg`, fill `accent`, width = sold fraction).
  4. **Just for you**: `SectionHeader` "Just for you", then a 2-column `ProductCard` grid, gap 10, 16 side padding.

### C7. Product list (`/products?category=&q=`)

- **Top bar**, white, padding 12, 1px divider at the bottom:
  - Row: back 44, `SearchField` (44, `surfaceAlt`) filling the space, a cart icon 44 with badge.
  - Row under it: a horizontally scrolling list of `AppChip`s, gap 8: "Popular", "Price ↑/↓", "4★ & up", "Free delivery". "Popular" is selected by default.
- **Body** on `background`, padding 12 at the top and 16 at the sides:
  - A row with "<n> results" (13, `muted`) on the left and a "Filters" text button with a tune icon (13 / w700, ink) on the right. Filters opens a bottom sheet with a price-range slider and category checkboxes.
  - A 2-column `ProductCard` grid, gap 10.
- Empty state: "No products found", "Try a different search or filter.", and a "Clear filters" button.

### C8. Categories browser (`/categories`, tab 2)

- **Top**: white, padding 14 × 16, 1px divider. "Categories" (20 / w800) above a read-only `SearchField` "Search in categories" → /search.
- **Body**: a row.
  - **Left rail**, 104 wide, `surfaceAlt` background, a list of category buttons, each at least 60 high, padding 8 × 10, text 12 aligned left:
    - selected: white background, a 4px `primary` bar on the left, text w800 primary
    - unselected: transparent, w600 `inkSoft`
  - **Right panel**, white, padding 14, gap 14:
    - a banner 92 high, radius 14, `deep` background: the category name (16 / w800 white) over "Top deals this week" (12 / w700 `accent`)
    - "Shop by type" (14 / w800)
    - a 3-column grid, gap 14 × 10, of that category's products: a 64×64 image (radius 16, placeholder) with the name below (11 / w600, centred, 2 lines). Tap opens product details.
    - "See all <category>" (`AppButton.outline` small) → /products?category=id

### C9. Product details (`/product-details`, extra: Product)

- **Image header**, 330 high, placeholder background, `PageView` of images (only one for now).
  - Overlay, 12 from the sides and 16 from the top: on the left a white 44 circle with a back chevron; on the right white 44 circles for share and cart (with badge), plus a wishlist heart.
  - Bottom-right: a "1 / n" pill (`deep` fill, white 12 / w700, padding 4 × 10).
- **Then sections**, white, padding 14 × 16, gap 8 between sections on `background`:
  1. **Price**: a baseline row of the price (26 / w800 primary), the old price (14, `muted`, line-through) and a `DiscountBadge`. Below, the name (16 / w700, line height 1.35) and a rating row: star 14, rating w700 ink, "(n ratings)", "·", "n sold", 13 `muted`.
  2. **Options**: a row "Colour" (14 / w700) with the selected value (14, `muted`) on the right. Below, chips 44 high, radius 10, padding 0 × 16: selected 2px primary border, `primaryTint` fill, primary text w700; unselected 1px border, white, w600.
  3. **Delivery**: 3 rows, gap 12, 13. Each has a 20 primary outline icon and text:
     - truck: "Standard delivery to <area> · ৳60" (w700) over "Arrives in 2–4 days" (`muted`)
     - wallet: "Cash on delivery available"
     - return arrow: "7-day easy return"
  4. **Reviews summary**: the average with stars, "See all (n)" → reviews screen, and a "Write a review" outline small button when allowed.
  5. **Description**: the text, 15, `inkSoft`, collapsed to 4 lines with "Read more".
- **Sticky bottom bar**: white, 76 high plus the safe area, 1px divider, padding 12, gap 10.
  - a 48×48 outline square chat button (radius 12, 1px border)
  - "Add to cart" (outline, flex 1, 48 high)
  - "Buy now" (primary, flex 1, 48 high)
  - When stock is 0, the two buttons are replaced by one disabled "Out of stock" button in `error` outline style.

### C10. Cart (`/cart`, tab 3)

- `AppTopBar` "My cart (n)" (no back on the tab), with an "Edit" text action that turns on delete mode.
- **Body** on `background`, padding 12, gap 12:
  - An item card (white, radius 14, padding 12, gap 12). Each item row, gap 10:
    - photo 80×80 (radius 10)
    - a column with the name (13 / w600, 2 lines) and the variant (12, `muted`, e.g. "Colour: Black")
    - a bottom row with the price (16 / w800 primary) on the left and a `QuantityStepper` on the right
    - a remove icon button (trash, `muted`) at the top-right
  - A voucher row: a white button, 52 high, radius 14, 1px **dashed** primary border, a ticket icon, "Apply a voucher" (14 / w700 primary), and "Coming soon" (13, `muted`) on the right.
- **Summary bar**: white, 1px divider on top, padding 12 × 16. On the left a column of "Total incl. delivery" (12, `muted`) and the total (20 / w800 primary). On the right `AppButton.primary` "Checkout (n)", auto width, padding 0 × 24, 50 high.
- **Empty state**: a cart icon, "Your cart is empty", "Add products you like and they'll show up here.", and a "Start shopping" button → /home.

### C11. Checkout (`/checkout`)

- `AppTopBar` "Checkout".
- **Body** on `background`, padding 12, gap 10:
  1. **Address card**: a pin icon 22 primary; a column with "<name> · <phone>" (14 / w700) and the address (13, `muted`, line height 1.4); "Change" (13 / w700 primary) on the right → /addresses?select=true. With no address: "Add a delivery address" plus a button → /add-address.
  2. **Package card**: "Package 1 · <n> items" (13 / w700) and below it, with a primary truck icon, "Standard delivery · arrives in 2–4 days" (13 / w600 primary), separated by a divider line.
  3. **Payment method card**: the title "Payment method" (15 / w800), then rows of at least 48 high, gap 12:
     - a 36×36 tile (radius 10, `surfaceAlt`) with a short label (COD, bK, Ng, Card; 11 / w800)
     - a column with the name (14 / w700) and a note (12, `muted`)
     - a radio on the right
     - Rows: "Cash on delivery — Pay the rider when it arrives" (enabled); "bKash", "Nagad", "Credit or debit card" (disabled, 50 % opacity, with a "Coming soon" tag in `surfaceAlt` / `muted` 11 / w700).
  4. **Order summary card**: rows "Items total", "Delivery" and (only when used) "Voucher" in `primary` with a minus sign; 13, label `muted`, value ink. Gap 8.
- **Bottom bar**: white, padding 12 × 16 + 20 bottom. On the left "Pay in cash on delivery" (12, `muted`) over the total (20 / w800 primary); on the right `AppButton.primary` "Place order" (52 high, padding 0 × 28, loading state).

### C12. Order confirmation (`/order-confirmation`)

- White page, padding 24 × 24 × 32.
- Centred, gap 16:
  - a 96 circle (`primaryTint`) containing a 64 circle (`primary`) with a white check (32, stroke 3)
  - "Order placed" (`headline`)
  - "We've received your order. You'll get updates as it moves." (15, `muted`, centred)
  - an info box (`background` fill, radius 14, padding 14 × 16, gap 10), with rows of `muted` label and w700–800 value:
    - Order number (order_number, or a short id)
    - Items
    - Payment ("Cash on delivery")
    - Deliver to (area, district)
- Bottom: `AppButton.primary` "Track my order" → /tracking/:id, then `AppButton.outline` "Continue shopping" → /home.

### C13. My orders (`/order-history`)

- **Top**: `AppTopBar` "My orders" with a scrollable tab bar under it (44 high). Tabs are 13; active w800 primary with a 3px primary indicator, inactive w600 `muted`.
  - **All**
  - **Processing** (pending, confirmed, processing)
  - **Shipped**
  - **Delivered**
  - **Cancelled**
- **Body** on `background`, padding 12, gap 10. Each order card (white, radius 14, padding 14, gap 12):
  - a row with the order number (13 / w700) on the left and `StatusText` on the right
  - a row with a 64×64 thumbnail (radius 10) and a column: the first item name (13 / w600, 2 lines, plus " + n more" when there are more) and "<n> items · placed <date>" (13, `muted`)
  - a divider (1px `divider`, padding-top 10), then a row with "Total **৳x**" (13, `muted`, the amount ink w800) and an outline small button that depends on status:
    - shipped → "Track"
    - delivered → "Write review" when allowed, else "Details"
    - otherwise → "Details"
- **Empty**: "No orders here yet." Tapping a card opens details.

### C14. Order details (`/order-details/:orderId`)

- `AppTopBar` "Order details".
- **Status banner** (`primary` fill, radius 16, padding 18, white text):
  - the status in capitals (12 / w700, `onPrimaryMuted`, letter-spacing 0.6)
  - the headline (22 / w800), e.g. "Order confirmed"
  - "Placed <date> · <order number>" (13, `onPrimaryMuted`)
- **Items card**: one row per item — thumbnail 56, name, "Qty n", and the line price on the right.
- **Delivery card**: the shipping address snapshot.
- **Payment card**: Items total, Delivery, Total (bold), Payment method.
- **Actions**: "Track order" (primary) when there is a shipment or the status is shipped; "Request a return" (outline) when delivered (Prompt 15); "Need help?" text button.

### C15. Tracking (`/tracking/:orderId`)

- `AppTopBar` with the title "Track order" and a subtitle "Order <number>" (12, `muted`).
- **Status card** (`primary`, radius 16, padding 18, gap 6):
  - the status (12 / w700 `onPrimaryMuted`, capitals)
  - "Arriving by <estimated date>", or "Preparing your order" when there is no date (22 / w800 white)
  - "With <courier> · Tracking <number>" (13, `onPrimaryMuted`), hidden when there is no shipment
- **Timeline card** (white, radius 14, padding 16). Each step is a row with gap 12:
  - **Marker column**, 22 wide:
    - done: a 22 circle in `primary` with a white check (12)
    - current: a 22 circle, white, with a 6px `primary` border
    - to do: a 22 circle, white, with a 2px `border` border
    - between steps: a 2px line in `border`, at least 26 high
  - **Text column**, 16 bottom padding:
    - the title: 14 / w800 ink when reached, 14 / w600 `muted` when not
    - the note or time (12, `muted`)
- **Steps**:
  - With tracking events: use the events in time order (the newest is current).
  - Without events, derive the steps from the order status: Order placed → Confirmed → Packed (processing) → Shipped → Out for delivery → Delivered.
  - Cancelled shows a single red step, "Cancelled".
- **Actions**: a 2-column row of outline buttons, 48 high: "Chat with seller" and "Get help".

### C16. Wishlist (`/wishlist`)

- `AppTopBar` "Wishlist (n)".
- **Body** on `background`, padding 12, gap 10. Each card (white, radius 14, padding 12, row gap 12):
  - photo 96×96 (radius 10), tappable to product details
  - a column with the name (13 / w600, 2 lines), `PriceText`, and an optional `DiscountBadge.outOfStock` "Out of stock" when stock is 0
  - a bottom-right row, gap 8: a 40×40 outline trash button (radius 10) and an `AppButton.primary` small "Move to cart" (disabled when out of stock)
- **Empty**: a heart icon, "Your wishlist is empty", "Tap the heart on any product to save it here.", and "Browse products".

### C17. Account (`/account`, tab 4)

- **Header** (`primary`, padding 24 × 16 × 20, row gap 14):
  - a 60 avatar circle (`primaryTint`) with the initial (22 / w800 primary)
  - a column with the name (18 / w800 white) and the phone or email (13, `onPrimaryMuted`)
  - an "Edit" pill (36 high, `primaryOnDark` fill, white 13 / w700, padding 0 × 12) → /edit-profile
  - A guest sees "Log in or sign up" instead, with an `AppButton.deal` small.
- **Body** on `background`, padding 12, gap 10:
  1. **My orders card**: a header row with "My orders" (15 / w800) and "View all" (13 / w700 primary). Below, a 5-column grid of shortcuts, each with an icon 24 primary over a label (11 / w600), at least 56 high:
     - To pay (card icon)
     - Processing (box icon)
     - Shipped (truck icon)
     - To review (star icon)
     - Returns (return icon)
     - Each opens /order-history at the matching tab.
  2. **Menu card** (white, radius 14). Rows are 50 high, padding 0 × 14, 1px `surfaceAlt` divider, label 14 / w600, an optional hint on the right (12, `muted`), and a chevron 16 `hint`. The rows, in order:
     - Wishlist (hint "<n> items")
     - My vouchers
     - Address book
     - Messages
     - Notifications
     - Help center
     - Settings
     - Sell on zollo

### C18. Edit profile (`/edit-profile`)

- `AppTopBar` "Edit profile".
- White body, padding 20 × 24, gap 16:
  - an 88 avatar circle (initial 32 / w800) with a "Change photo" text button under it (disabled, TODO)
  - Full name
  - Phone (`PhoneField`)
  - Email (read-only, `background` fill, with the tag "Verified" in 12 / w800 primary on the right when the email is confirmed)
- Bottom: `AppButton.primary` "Save changes" (padding 12 × 24 × 24).

### C19. Search (`/search`)

- **Top**, white, padding 12, 1px divider: back 44, a `SearchField` with autofocus and a 1.5px primary border, and a camera icon 44 (disabled).
- **While typing**: a suggestion list. Rows are at least 48 high, padding 0 × 16, with a 1px `surfaceAlt` divider: a search icon 16 `hint`, the suggestion text with the typed part in **w800**, and the category on the right (12, `muted`). A tap opens /products?q=.
- **Empty field**:
  - "Recent searches" (15 / w800) with "Clear" (13 / w700 `muted`), then wrap chips (36 high, `surfaceAlt`, 13 / w600)
  - "Trending now": a 2-column numbered list (14). Numbers 1–3 are w800 in `warning`; the rest w800 `muted`.

### C20. Product reviews (`/product-reviews`, extra: Product)

- `AppTopBar` "Ratings & reviews".
- **Summary card**:
  - on the left the average (32 / w800) with stars and "<n> ratings" (12, `muted`)
  - on the right 5 distribution rows (5★ to 1★): a label, a bar 6 high, radius 3 (track `divider`, fill `star`), and the count
- **Review cards** (white, radius 14, padding 14, gap 6):
  - stars (14) with the date (12, `muted`) on the right
  - "Verified buyer" (12 / w700 primary)
  - the comment (14, `inkSoft`)
- **Empty**: "No reviews yet. Be the first to review it."

### C21. Write a review (`/write-review`, extra: Product)

- `AppTopBar` "Write a review".
- **Body** on `background`, padding 12, gap 10:
  1. **Product row card**: thumbnail 56 (radius 10) with the name (13 / w700).
  2. **Rating card**, centred, padding 18 × 14, gap 10:
     - "How would you rate it?" (15 / w800)
     - 5 star buttons, each 48×48 with a 36 icon: filled `star` up to the selection, outline `switchOff` after
     - the word for the rating (14 / w700 primary): Poor, Fair, Good, Very good, Excellent
  3. **Text card**: the label "Your review", and a multiline field (5 lines, radius 12, 1px border, hint "What did you like or dislike? How was the quality?", max 2000 characters with a counter).
- **Bottom bar**: `AppButton.primary` "Submit review" (loading). On success, show a SnackBar and pop.

### C22. Address book (`/addresses`, optional `?select=true`)

- `AppTopBar` "Address book", or "Choose address" in select mode.
- **Body** on `background`, padding 12, gap 10. Each address card (white, radius 14, padding 14, gap 6, 13):
  - **Top row**:
    - the label tag (11 / w800, padding 2 × 8, radius 6): HOME as white on `primary`; OFFICE and OTHER as `inkSoft` on `surfaceAlt`
    - a "Default" tag (`primary` on `primaryTint`) when default
    - "Edit" (13 / w700 primary) on the right
  - "<name> · <phone>" (14 / w700)
  - the address line, area, district, division (13, `muted`, line height 1.45)
  - non-default addresses: a "Set as default" text button (13 / w700 primary)
  - the default card has a 1.5px primary border; the others a 1px `divider` border
  - **select mode**: a radio on the right; a tap selects and pops with the address
  - swipe left to delete, with a confirm dialog
- **Bottom**: `AppButton.primary` with a plus icon, "Add new address" (padding 12 × 16 × 24).

### C23. Add / edit address (`/add-address`, `/edit-address`)

- `AppTopBar` "Add address" or "Edit address".
- White body, padding 16 × 20, gap 12. Fields are 46 high, radius 10, label 12 / w700:
  1. A "Use my current location" button (44 high, `primaryTint` fill, 1px primary border, primary 14 / w700, location icon). It is disabled with a "Coming soon" tooltip.
  2. A 2-column row: Full name, Phone.
  3. Division (dropdown of all 8 divisions: Dhaka, Chattogram, Khulna, Rajshahi, Sylhet, Barishal, Rangpur, Mymensingh).
  4. A 2-column row: District (a dropdown filtered by division), Area (a text field).
  5. Address (multiline, 2 lines, hint "House, road, building, landmark").
  6. Label: chips Home / Office / Other (`AppChip`, 40 high).
  7. A "Make this my default address" checkbox.
- **Bottom**: `AppButton.primary` "Save address".
- **Note for this step**: AddressRepository currently drops division, district, area and label. The UI must still collect them; the data fix comes in the optional Prompt D.

### C24. My vouchers (`/vouchers`)

- `AppTopBar` "My vouchers".
- **Body** on `background`, padding 12, gap 10:
  - A code row card (white, radius 14, padding 10, gap 8): a text field "Enter a voucher code" (44, uppercase) and a primary small "Add" button.
  - **Voucher tickets** (white, radius 14, at least 96 high, a row):
    - **Left block**, 96 wide, `deep` fill, centred: the amount (20 / w800 `accent`, e.g. "৳100", "10%", "Free") over "OFF" (11 / w700 white).
    - **Right block**, padding 12, with a 2px **dashed** `divider` left border:
      - the title (14 / w800)
      - the rule (13, `muted`, e.g. "Min. spend ৳999 · all sellers")
      - a bottom row with the expiry (12 / w700 `warning`) and a "Use" outline button (32 high)

### C25. Notifications (`/notifications`)

- `AppTopBar` "Notifications" with a "Mark all read" action, and tabs All / Orders / Promotions (same style as C13).
- A list on white. Rows have padding 14 × 16, row gap 12, and a 1px `surfaceAlt` divider:
  - a 40×40 tile (radius 12) with a short tag (11 / w800): `primaryTint` for orders, `discountBg` for promotions
  - a column with the title (14 / w800), the body (13, `muted`, line height 1.4) and the time (11, `hint`)
  - an 8×8 `primary` dot when unread
  - a tap marks the row read and opens its deep link

### C26a. Messages (`/messages`)

- `AppTopBar` "Messages".
- A list on white. Rows are at least 76 high, padding 12 × 16, row gap 12, with a 1px `surfaceAlt` divider:
  - a 48×48 store avatar (radius 14, `primaryTint`, store icon primary)
  - a column with:
    - a top row: the seller name (14 / w800) and the time (11, `hint`)
    - a bottom row: the last message (13, `muted`, 1 line, ellipsis), plus an unread count badge (20 high, `primary`, white 11 / w800) when unread

### C26b. Chat room (`/messages/:conversationId`)

- **Top bar**: back, the seller name (16 / w800), and "Usually replies within 1 hour" (12 / w700 primary).
- **Product context card** (white, radius 12, margin 10 × 12, padding 10): thumbnail 44, the name (12 / w700), and the price (12 / w800 primary). Tap opens the product.
- **Messages** on `background`, padding 12, gap 8, a reversed list. There is a "Today" date chip (11, `hint`).
  - **My bubble**: right-aligned, max 78 % width, `primary` fill, white 14 text, radius 16-16-4-16, padding 10 × 12, the time 10 `onPrimaryMuted`.
  - **Their bubble**: left-aligned, white, ink text, radius 16-16-16-4, the time 10 `hint`.
- **Input bar** (white, 1px divider, padding 10 × 12 × 20, gap 8):
  - a 44 circle `surfaceAlt` photo button
  - a pill text field (44 high, radius 22, 1px border)
  - a 44 circle `primary` send button with a white send icon
  - the send button is disabled while the text is empty

### C27. Settings (`/settings`) and change password (`/settings/change-password`)

- **Settings**: `AppTopBar` "Settings". The body on `background`, padding 12, gap 12:
  1. **Language card**: the caption "LANGUAGE" (12 / w800 `muted`, letter-spacing 0.6), and a segmented control (`surfaceAlt` track, radius 12, padding 4, 2 options 40 high; the selected option is white with 14 / w800 primary, the other 14 / w600 `inkSoft`): English / বাংলা.
  2. **Notifications card**: the caption "NOTIFICATIONS". Rows are at least 52 high with a title (14 / w700), a note (12, `muted`) and a `Switch` (on: primary track; off: `switchOff`):
     - Order updates
     - Messages
     - Price drops
     - Offers and campaigns
  3. **Links card**: Change password, Privacy policy, Terms of use (rows 50 high with a chevron).
  4. `AppButton.danger` "Log out" (50 high, white fill), then the text button "Delete my account" (13 / w700 `muted`), and the caption "Version <x.y.z>" (11, `hint`) from package_info, or a constant if that package isn't present.
- **Change password**: `AppTopBar` "Change password". White body, padding 20 × 24, gap 16:
  - Current password, with a "Forgot current password?" link right-aligned under it
  - New password
  - Confirm new password
  - the password rules checklist (C5)
  - a "Log out of all other devices" checkbox
  - bottom: `AppButton.primary` "Update password"

### C28. Return request (`/return-request`, extra: OrderModel)

- `AppTopBar` "Request a return".
- **Body** on `background`, padding 12, gap 10:
  1. **Item card**: thumbnail 56, the name, and "৳price · return window ends <date>" (13, `muted`). With several items, show a picker list of checkboxes.
  2. **Reason card**: the title "Why are you returning it?" (15 / w800), then radio rows at least 44 high (14):
     - Item is damaged
     - Wrong item received
     - Not as described
     - Missing parts
     - Changed my mind
  3. **Details card**: "Tell us more" (multiline, 3 lines) and a 56×56 dashed-border "add photo" button with the text "Photos help us approve your return faster" (13, `muted`).
  4. **Refund card**: "Refund to <method>" (14 / w700) over "Original payment method" (12, `muted`); for cash on delivery it says "Refund to bKash or bank".
- **Bottom**: `AppButton.primary` "Submit return request".

---

# Optional — Prompt D · Fix the data bugs found in the code review

Run this **before Prompt 8** if you want real orders to work correctly. It changes data code and the Supabase schema, so commit first.

```
Read docs/ui_build_plan.md Part A. Fix these data bugs, one commit each, with tests:
1. Orders: SupabaseOrderRepository sends an `items` column that doesn't exist and inserts
   order_items with `price` instead of `unit_price`; the error is swallowed, so orders are
   saved without items. Insert into orders (with subtotal, shipping_fee, total_amount,
   payment_method, shipping_name, shipping_phone, shipping_address) and then into
   order_items (unit_price, quantity, product_name, product_id). Remove the fallback retries
   and stop swallowing errors. Read items back from order_items with an embedded select:
   orders.select('*, order_items(*)'), instead of one query per order.
2. Map PaymentMethod to the DB values: cashOnDelivery -> 'cash_on_delivery'.
3. AddressRepository: also save and read division, district, area and label; add a `label`
   text column via a migration (see below). getAddresses must not swallow errors.
4. Tracking: order tracking_events by occurred_at (not timestamp) and read occurred_at and
   estimated_delivery in the models; align ShipmentStatus with the DB values
   (pending, confirmed, processing, shipped, out_for_delivery, delivered, cancelled, failed).
5. Wishlist and reviews upsert need unique constraints.
Write all schema changes in supabase/migrations/<timestamp>_fix_constraints.sql:
  - alter table wishlist alter column user_id set not null, alter column product_id set not null;
  - create unique index on wishlist(user_id, product_id);
  - create unique index on product_reviews(product_id, user_id);
  - create unique index on cart_items(user_id, product_id);
  - alter table addresses add column if not exists label text default 'Home';
  - indexes on every user_id, order_id, product_id, shipment_id foreign key column;
  - a trigger that inserts a profiles row (id, full_name, phone from raw_user_meta_data)
    on auth.users insert, plus a backfill for existing users;
  - RLS enabled on all tables with own-row policies for wishlist, cart_items, addresses,
    orders, order_items (via the parent order), product_reviews, and public read for active
    products and categories.
Do not run the migration yourself. Show me the SQL so I can run it in the Supabase SQL editor.
Later, the order insert should move to a place_order() Postgres function so prices come from
the database; leave a TODO for that.
```
