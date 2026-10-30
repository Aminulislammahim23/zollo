/// `shipments.status` / `tracking_events.status` values in the database.
enum ShipmentStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  processing('processing', 'Packing'),
  shipped('shipped', 'Shipped'),
  outForDelivery('out_for_delivery', 'Out for delivery'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled'),
  failed('failed', 'Delivery failed');

  const ShipmentStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ShipmentStatus? fromDb(String? value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }
    return null;
  }
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

class TrackingEvent {
  final String id;
  final String shipmentId;
  final String status;
  final String description;
  final String? location;

  /// `tracking_events.occurred_at`.
  final DateTime occurredAt;

  const TrackingEvent({
    required this.id,
    required this.shipmentId,
    required this.status,
    required this.description,
    this.location,
    required this.occurredAt,
  });

  ShipmentStatus? get shipmentStatus => ShipmentStatus.fromDb(status);

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      id: map['id'] as String? ?? '',
      shipmentId: map['shipment_id'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      description: map['description'] as String? ?? '',
      location: map['location'] as String?,
      occurredAt: _date(map['occurred_at']) ?? DateTime.now(),
    );
  }
}

class Shipment {
  final String id;
  final String orderId;
  final String trackingNumber;
  final String? courierName;
  final String status;

  /// `shipments.estimated_delivery`.
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final List<TrackingEvent> events;

  const Shipment({
    required this.id,
    required this.orderId,
    required this.trackingNumber,
    this.courierName,
    required this.status,
    this.estimatedDelivery,
    required this.createdAt,
    this.events = const [],
  });

  factory Shipment.fromMap(
    Map<String, dynamic> map, {
    List<TrackingEvent>? events,
  }) {
    final rawEvents = map['tracking_events'] as List<dynamic>?;
    final parsedEvents = rawEvents != null
        ? rawEvents
              .map(
                (e) =>
                    TrackingEvent.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
        : (events ?? []);

    parsedEvents.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    return Shipment(
      id: map['id'] as String? ?? '',
      orderId: map['order_id'] as String? ?? '',
      trackingNumber: map['tracking_number'] as String? ?? '',
      courierName: map['courier_name'] as String?,
      status: map['status'] as String? ?? 'pending',
      estimatedDelivery: _date(map['estimated_delivery']),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      events: parsedEvents,
    );
  }

  ShipmentStatus? get shipmentStatus => ShipmentStatus.fromDb(status);
}
