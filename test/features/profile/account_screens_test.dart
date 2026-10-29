import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/address/data/address_repository.dart';
import 'package:zollo/features/address/domain/address_model.dart';
import 'package:zollo/features/address/presentation/providers/address_provider.dart';
import 'package:zollo/features/address/presentation/screens/add_edit_address_screen.dart';
import 'package:zollo/features/address/presentation/screens/address_list_screen.dart';
import 'package:zollo/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:zollo/features/profile/presentation/screens/profile_screen.dart';

import '../../support/test_helpers.dart';

class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository([List<Address>? initial]) : addresses = initial ?? [];

  final List<Address> addresses;

  @override
  Future<List<Address>> getAddresses() async => List.of(addresses);

  @override
  Future<void> addAddress(Address address) async =>
      addresses.add(address.copyWith(id: 'a${addresses.length + 1}'));

  @override
  Future<void> updateAddress(Address address) async {
    final i = addresses.indexWhere((a) => a.id == address.id);
    addresses[i] = address;
  }

  @override
  Future<void> deleteAddress(String id) async => addresses.removeWhere((a) => a.id == id);

  @override
  Future<void> setDefaultAddress(String id) async {
    for (var i = 0; i < addresses.length; i++) {
      addresses[i] = addresses[i].copyWith(isDefault: addresses[i].id == id);
    }
  }
}

Address _address(String id, {bool isDefault = false, String label = 'HOME'}) => Address(
      id: id,
      userId: 'user-1',
      fullName: 'Rahim Uddin',
      phone: '01712345678',
      addressLine: 'House 12, Road 4',
      city: 'Dhaka City',
      postalCode: '',
      area: 'Dhanmondi',
      label: label,
      isDefault: isDefault,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/account', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/edit-profile', builder: (_, _) => const EditProfileScreen()),
    GoRoute(
      path: '/addresses',
      builder: (_, s) => AddressListScreen(isSelecting: s.uri.queryParameters['select'] == 'true'),
    ),
    GoRoute(path: '/add-address', builder: (_, _) => const AddEditAddressScreen()),
    GoRoute(path: '/edit-address', builder: (_, s) => AddEditAddressScreen(address: s.extra as Address)),
    stubRoute('/login', 'Login destination'),
    stubRoute('/order-history', 'Orders destination'),
    stubRoute('/wishlist'),
    stubRoute('/settings'),
  ];

  testWidgets('Account shows the user and opens order tabs', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/account', user: FakeUser());
    await tester.pump();

    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('+880 1712-345678'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Shipped'));
    await tester.pumpAndSettle();
    expect(find.text('Orders destination'), findsOneWidget);
  });

  testWidgets('Account invites guests to log in', (tester) async {
    await pumpRoutes(tester, routes: routes, initialLocation: '/account');
    expect(find.text('Log in or sign up'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
  });

  testWidgets('Edit profile saves name and phone', (tester) async {
    final auth = FakeAuthRepository(user: FakeUser());
    await pumpRoutes(tester, routes: routes, initialLocation: '/edit-profile', auth: auth);

    expect(find.text('Verified'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Karim Ahmed');
    await tester.enterText(find.byType(TextFormField).at(1), '01812345678');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump();

    expect(auth.calls, ['updateProfile:Karim Ahmed:+8801812345678']);
  });

  testWidgets('Address book sets default and select mode pops', (tester) async {
    final repo = FakeAddressRepository([_address('a1', isDefault: true), _address('a2', label: 'OFFICE')]);
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/addresses',
      user: FakeUser(),
      overrides: [addressRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('OFFICE'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    await tester.tap(find.text('Set as default'));
    await tester.pump();
    await tester.pump();
    expect(repo.addresses.firstWhere((a) => a.id == 'a2').isDefault, isTrue);
  });

  testWidgets('Add address validates the BD phone number', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = FakeAddressRepository();
    await pumpRoutes(
      tester,
      routes: routes,
      initialLocation: '/add-address',
      user: FakeUser(),
      overrides: [addressRepositoryProvider.overrideWithValue(repo)],
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rahim Uddin');
    await tester.enterText(fields.at(1), '12345');
    await tester.enterText(fields.at(2), 'Dhanmondi');
    await tester.enterText(fields.at(3), 'House 12, Road 4');
    await tester.tap(find.text('Save address'));
    await tester.pump();
    expect(find.text('Enter a valid BD mobile number, e.g. 1712345678'), findsOneWidget);
    expect(repo.addresses, isEmpty);

    await tester.enterText(fields.at(1), '01712345678');
    await tester.tap(find.text('Office'));
    await tester.tap(find.text('Save address'));
    await tester.pump();
    await tester.pump();
    expect(repo.addresses.single.label, 'OFFICE');
    expect(repo.addresses.single.area, 'Dhanmondi');
  });
}
