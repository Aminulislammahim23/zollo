import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Values the shop can change without an app release (`app_config` table).
class AppConfigRepository {
  AppConfigRepository(this._client);

  final SupabaseClient _client;

  /// `app_config.delivery_fee`, or null when it can't be read.
  Future<double?> fetchDeliveryFee() async {
    final row = await _client
        .from('app_config')
        .select('value')
        .eq('key', 'delivery_fee')
        .maybeSingle();
    final value = row?['value'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Reads the fee at start-up. Any failure (offline, slow network, table
  /// missing) falls back to [AppConstants.deliveryFee] so launch never blocks.
  static Future<double> loadDeliveryFee(
    SupabaseClient client, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final fee = await AppConfigRepository(client)
          .fetchDeliveryFee()
          .timeout(timeout);
      return fee != null && fee >= 0 ? fee : AppConstants.deliveryFee;
    } catch (_) {
      return AppConstants.deliveryFee;
    }
  }
}

/// The delivery fee shown everywhere in the app. Overridden in main() with
/// the value loaded from `app_config`; `place_order()` charges the same one.
final deliveryFeeProvider = Provider<double>((ref) => AppConstants.deliveryFee);
