import 'package:flutter/material.dart';
import '../../domain/tracking_event_model.dart';

class TrackingTimeline extends StatelessWidget {
  final List<TrackingEvent> events;

  const TrackingTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final steps = events.isNotEmpty
        ? events
            .map((e) => {
                  'title': e.status.toUpperCase(),
                  'subtitle': e.description,
                  'done': true,
                })
            .toList()
        : [
            {
              'title': 'Order placed',
              'subtitle': 'Stock reserved for you',
              'done': true,
            },
            {
              'title': 'Confirmed',
              'subtitle': 'Paid with bKash',
              'done': true,
            },
            {
              'title': 'Packed',
              'subtitle': 'Seller packed your items',
              'done': true,
            },
            {
              'title': 'Shipped',
              'subtitle': 'Picked up by the courier',
              'done': true,
            },
            {
              'title': 'In transit',
              'subtitle': 'Reached the Dhaka sorting hub',
              'active': true,
            },
            {
              'title': 'Delivered',
              'subtitle': 'Rider will call before arriving',
              'done': false,
            },
          ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isDone = step['done'] == true;
        final isActive = step['active'] == true;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? const Color(0xFF006B54)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone || isActive
                          ? const Color(0xFF006B54)
                          : Colors.grey.shade400,
                      width: isActive ? 4 : 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: isDone
                        ? const Color(0xFF006B54)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isActive || isDone
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
