import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/tracking_event_model.dart';

class TrackingRepository {
  final SupabaseClient _supabase;

  TrackingRepository(this._supabase);

  Future<List<Shipment>> getShipmentsForOrder(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to view shipment tracking.');
    }

    final orderRow = await _supabase
        .from('orders')
        .select('id, user_id')
        .eq('id', orderId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (orderRow == null) {
      throw StateError('Order not found or unauthorized access.');
    }

    try {
      final shipmentRows = await _supabase
          .from('shipments')
          .select('*, tracking_events(*)')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return shipmentRows.map((row) {
        return Shipment.fromMap(Map<String, dynamic>.from(row as Map));
      }).toList();
    } catch (_) {
      // Return empty list if shipments table doesn't exist yet in the DB
      return [];
    }
  }

  Future<List<TrackingEvent>> getTrackingEvents(String shipmentId) async {
    try {
      final eventRows = await _supabase
          .from('tracking_events')
          .select()
          .eq('shipment_id', shipmentId)
          .order('timestamp', ascending: true);

      return eventRows.map((row) {
        return TrackingEvent.fromMap(Map<String, dynamic>.from(row as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
