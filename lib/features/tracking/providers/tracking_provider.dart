import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/tracking_repository.dart';
import '../domain/tracking_event_model.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(Supabase.instance.client);
});

final shipmentsByOrderProvider = FutureProvider.family<List<Shipment>, String>((
  ref,
  orderId,
) async {
  return ref.watch(trackingRepositoryProvider).getShipmentsForOrder(orderId);
});

final trackingEventsProvider =
    FutureProvider.family<List<TrackingEvent>, String>((ref, shipmentId) async {
      return ref
          .watch(trackingRepositoryProvider)
          .getTrackingEvents(shipmentId);
    });
