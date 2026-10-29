import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/address_model.dart';

class AddressRepository {
  final SupabaseClient _supabase;

  AddressRepository(this._supabase);

  Future<List<Address>> getAddresses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to view addresses.');
    }

    try {
      final rows = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return rows
          .map((row) => Address.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addAddress(Address address) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to add an address.');
    }

    if (address.isDefault) {
      try {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      } catch (_) {}
    }

    final payload = {
      'user_id': user.id,
      'recipient_name': address.fullName,
      'phone': address.phone,
      'address_line': address.addressLine,
      'city': address.city,
      'postal_code': address.postalCode.isEmpty ? null : address.postalCode,
      'country': address.country,
      'is_default': address.isDefault,
    };

    try {
      await _supabase.from('addresses').insert(payload);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to update an address.');
    }

    if (address.isDefault) {
      try {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      } catch (_) {}
    }

    final payload = {
      'recipient_name': address.fullName,
      'phone': address.phone,
      'address_line': address.addressLine,
      'city': address.city,
      'postal_code': address.postalCode.isEmpty ? null : address.postalCode,
      'country': address.country,
      'is_default': address.isDefault,
    };

    try {
      await _supabase
          .from('addresses')
          .update(payload)
          .eq('id', address.id)
          .eq('user_id', user.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to delete an address.');
    }

    await _supabase
        .from('addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> setDefaultAddress(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in.');
    }

    try {
      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);
    } catch (_) {}

    await _supabase
        .from('addresses')
        .update({'is_default': true})
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
