import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/tracking/domain/tracking_event_model.dart';
import 'package:zollo/features/tracking/presentation/widgets/tracking_timeline.dart';
import 'package:flutter/material.dart';

void main() {
  group('Tracking Feature Unit & Widget Tests', () {
    test('TrackingEvent reads occurred_at', () {
      final now = DateTime.now().toUtc();
      final eventMap = {
        'id': 'ev-1',
        'shipment_id': 'sh-1',
        'status': 'out_for_delivery',
        'description': 'Package picked up by courier',
        'location': 'Dhaka Hub',
        'occurred_at': now.toIso8601String(),
      };

      final event = TrackingEvent.fromMap(eventMap);
      expect(event.id, 'ev-1');
      expect(event.shipmentId, 'sh-1');
      expect(event.status, 'out_for_delivery');
      expect(event.shipmentStatus, ShipmentStatus.outForDelivery);
      expect(event.description, 'Package picked up by courier');
      expect(event.location, 'Dhaka Hub');
      expect(event.occurredAt, now);
    });

    test('ShipmentStatus maps every database value', () {
      const db = [
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'out_for_delivery',
        'delivered',
        'cancelled',
        'failed',
      ];
      expect(ShipmentStatus.values.map((s) => s.dbValue), db);
      expect(ShipmentStatus.fromDb('in_transit'), isNull);
    });

    test('Shipment reads estimated_delivery', () {
      final shipment = Shipment.fromMap({
        'id': 'sh-1',
        'status': 'shipped',
        'estimated_delivery': '2026-11-02',
      });
      expect(shipment.estimatedDelivery, DateTime(2026, 11, 2));
      expect(shipment.shipmentStatus, ShipmentStatus.shipped);
    });

    test('Shipment chronological event sorting', () {
      final t1 = DateTime(2023, 10, 1, 10, 0);
      final t2 = DateTime(2023, 10, 2, 12, 0);

      final shipmentMap = {
        'id': 'sh-1',
        'order_id': 'ord-1',
        'tracking_number': 'TRK123456',
        'courier_name': 'RedX',
        'status': 'in_transit',
        'created_at': t1.toIso8601String(),
        'tracking_events': [
          {
            'id': 'e2',
            'shipment_id': 'sh-1',
            'status': 'in_transit',
            'description': 'Out for delivery',
            'occurred_at': t2.toIso8601String(),
          },
          {
            'id': 'e1',
            'shipment_id': 'sh-1',
            'status': 'picked_up',
            'description': 'Picked up',
            'occurred_at': t1.toIso8601String(),
          },
        ],
      };

      final shipment = Shipment.fromMap(shipmentMap);
      expect(shipment.events.length, 2);
      expect(shipment.events[0].id, 'e1'); // Earlier timestamp first
      expect(shipment.events[1].id, 'e2'); // Later timestamp second
    });

    testWidgets('TrackingTimeline renders events correctly', (tester) async {
      final events = [
        TrackingEvent(
          id: '1',
          shipmentId: 'sh-1',
          status: 'picked_up',
          description: 'Package picked up',
          location: 'Warehouse',
          occurredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TrackingTimeline(events: events)),
        ),
      );

      expect(find.text('Package picked up'), findsOneWidget);
    });
  });
}
