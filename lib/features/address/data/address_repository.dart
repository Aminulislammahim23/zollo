import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/address_model.dart';

class AddressRepository {
  final SupabaseClient _supabase;

  AddressRepository(this._supabase);

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to manage your addresses.');
    }
    return user.id;
  }

  Future<List<Address>> getAddresses() async {
    final rows = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', _userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(Address.fromMap).toList();
  }

  /// Only one default per user is allowed (unique index), so rows are
  /// written with is_default false and then promoted atomically by
  /// set_default_address().
  Future<void> addAddress(Address address) async {
    final row = await _supabase
        .from('addresses')
        .insert({
          ...address.toWriteMap(),
          'user_id': _userId,
          'is_default': false,
        })
        .select('id')
        .single();
    if (address.isDefault) await setDefaultAddress(row['id'] as String);
  }

  Future<void> updateAddress(Address address) async {
    await _supabase
        .from('addresses')
        .update(address.toWriteMap())
        .eq('id', address.id)
        .eq('user_id', _userId);
    if (address.isDefault) await setDefaultAddress(address.id);
  }

  Future<void> deleteAddress(String id) async {
    await _supabase
        .from('addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Clears the old default and sets the new one in one transaction.
  Future<void> setDefaultAddress(String id) async {
    await _supabase.rpc('set_default_address', params: {'p_address_id': id});
  }
}
