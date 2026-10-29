import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/address_repository.dart';
import '../../domain/address_model.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(Supabase.instance.client);
});

final addressListProvider =
    AsyncNotifierProvider<AddressListNotifier, List<Address>>(
  AddressListNotifier.new,
);

class AddressListNotifier extends AsyncNotifier<List<Address>> {
  AddressRepository get _repository => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() async {
    ref.watch(currentUserProvider.select((u) => u?.id));
    return _repository.getAddresses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getAddresses());
  }

  Future<void> addAddress(Address address) async {
    await _repository.addAddress(address);
    await refresh();
  }

  Future<void> updateAddress(Address address) async {
    await _repository.updateAddress(address);
    await refresh();
  }

  Future<void> deleteAddress(String id) async {
    await _repository.deleteAddress(id);
    await refresh();
  }

  Future<void> setDefault(String id) async {
    await _repository.setDefaultAddress(id);
    await refresh();
  }
}

final defaultAddressProvider = FutureProvider<Address?>((ref) async {
  final addresses = await ref.watch(addressListProvider.future);
  try {
    return addresses.firstWhere((a) => a.isDefault);
  } catch (_) {
    return addresses.isNotEmpty ? addresses.first : null;
  }
});
