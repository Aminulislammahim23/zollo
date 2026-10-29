import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/wishlist/presentation/providers/wishlist_provider.dart';

import '../../support/test_helpers.dart';

void main() {
  test('guests get an empty wishlist without touching the repository', () async {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(null),
      wishlistRepositoryProvider.overrideWithValue(FakeWishlistRepository({'p1'})),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(wishlistProvider.future), isEmpty);
  });

  test('toggle adds and removes for a signed-in user', () async {
    final repo = FakeWishlistRepository({'p1'});
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(FakeUser()),
      wishlistRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(wishlistProvider.future), {'p1'});

    await container.read(wishlistProvider.notifier).toggle('p2');
    expect(container.read(wishlistProvider).value, {'p1', 'p2'});
    expect(repo.ids, {'p1', 'p2'});

    await container.read(wishlistProvider.notifier).toggle('p1');
    expect(repo.ids, {'p2'});
  });
}
