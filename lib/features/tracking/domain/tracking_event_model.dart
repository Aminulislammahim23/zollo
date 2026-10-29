enum ShipmentStatus {
  pending,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  exception,
}

class TrackingEvent {
  final String id;
  final String shipmentId;
  final String status;
  final String description;
  final String? location;
  final DateTime timestamp;

  const TrackingEvent({
    required this.id,
    required this.shipmentId,
    required this.status,
    required this.description,
    this.location,
    required this.timestamp,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      id: map['id'] as String? ?? '',
      shipmentId: map['shipment_id'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      description: map['description'] as String? ?? '',
      location: map['location'] as String?,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'shipment_id': shipmentId,
    'status': status,
    'description': description,
    'location': location,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

class Shipment {
  final String id;
  final String orderId;
  final String trackingNumber;
  final String? courierName;
  final String status;
  final DateTime? estimatedDeliveryDate;
  final DateTime createdAt;
  final List<TrackingEvent> events;

  const Shipment({
    required this.id,
    required this.orderId,
    required this.trackingNumber,
    this.courierName,
    required this.status,
    this.estimatedDeliveryDate,
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

    parsedEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Shipment(
      id: map['id'] as String? ?? '',
      orderId: map['order_id'] as String? ?? '',
      trackingNumber: map['tracking_number'] as String? ?? '',
      courierName: map['courier_name'] as String?,
      status: map['status'] as String? ?? 'pending',
      estimatedDeliveryDate: map['estimated_delivery_date'] != null
          ? DateTime.tryParse(map['estimated_delivery_date'] as String)
          : null,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      events: parsedEvents,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'tracking_number': trackingNumber,
    'courier_name': courierName,
    'status': status,
    'estimated_delivery_date': estimatedDeliveryDate?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
