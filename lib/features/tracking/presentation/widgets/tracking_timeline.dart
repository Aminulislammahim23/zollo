import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../domain/tracking_event_model.dart';

enum TimelineStepState { done, current, todo, cancelled }

class TimelineStep {
  const TimelineStep({required this.title, this.note, required this.state});

  final String title;
  final String? note;
  final TimelineStepState state;

  bool get reached => state != TimelineStepState.todo;

  /// Tracking events in time order; the newest one is current.
  static List<TimelineStep> fromEvents(List<TrackingEvent> events) {
    final sorted = [...events]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return [
      for (var i = 0; i < sorted.length; i++)
        TimelineStep(
          title: sorted[i].description.isNotEmpty
              ? sorted[i].description
              : _humanize(sorted[i].status),
          note: [
            if (sorted[i].location != null && sorted[i].location!.isNotEmpty)
              sorted[i].location!,
            formatDateTime(sorted[i].timestamp),
          ].join(' · '),
          state: i == sorted.length - 1
              ? TimelineStepState.current
              : TimelineStepState.done,
        ),
    ];
  }

  /// Steps derived from the order status when no shipment events exist.
  static List<TimelineStep> fromOrder(OrderModel order) {
    if (order.status == OrderStatus.cancelled) {
      return [
        TimelineStep(
          title: 'Cancelled',
          note: 'Placed ${formatDateTime(order.createdAt)}',
          state: TimelineStepState.cancelled,
        ),
      ];
    }

    const titles = [
      'Order placed',
      'Confirmed',
      'Packed',
      'Shipped',
      'Out for delivery',
      'Delivered',
    ];
    final reached = switch (order.status) {
      OrderStatus.pending => 0,
      OrderStatus.confirmed => 1,
      OrderStatus.processing => 2,
      OrderStatus.shipped => 3,
      OrderStatus.delivered => 5,
      OrderStatus.cancelled => 0,
    };
    final allDone = order.status == OrderStatus.delivered;

    return [
      for (var i = 0; i < titles.length; i++)
        TimelineStep(
          title: titles[i],
          note: i == 0
              ? formatDateTime(order.createdAt)
              : (i == reached && !allDone ? 'In progress' : null),
          state: i < reached || allDone
              ? TimelineStepState.done
              : i == reached
              ? TimelineStepState.current
              : TimelineStepState.todo,
        ),
    ];
  }

  static String _humanize(String status) {
    final words = status.replaceAll('_', ' ').trim();
    return words.isEmpty
        ? 'Update'
        : words[0].toUpperCase() + words.substring(1);
  }
}

/// Vertical timeline (spec C15). Pass either [events] or [steps].
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, this.events = const [], this.steps});

  final List<TrackingEvent> events;
  final List<TimelineStep>? steps;

  @override
  Widget build(BuildContext context) {
    final items = steps ?? TimelineStep.fromEvents(events);
    if (items.isEmpty) {
      return Text(
        'No tracking updates yet.',
        style: AppText.caption.withColor(AppColors.muted),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      _Marker(state: items[i].state),
                      if (i < items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            constraints: const BoxConstraints(minHeight: 26),
                            color: AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < items.length - 1 ? AppSpacing.l : 0,
                      top: 1,
                    ),
                    child: Semantics(
                      label: '${items[i].title}, ${items[i].state.name}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: AppText.menuLabel
                                .withWeight(
                                  items[i].reached
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                )
                                .withColor(
                                  items[i].state == TimelineStepState.cancelled
                                      ? AppColors.error
                                      : items[i].reached
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                          ),
                          if (items[i].note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                items[i].note!,
                                style: AppText.caption.withColor(
                                  AppColors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.state});

  final TimelineStepState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TimelineStepState.done => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: AppColors.white),
      ),
      TimelineStepState.current => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 6),
        ),
      ),
      TimelineStepState.todo => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      ),
      TimelineStepState.cancelled => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 12, color: AppColors.white),
      ),
    };
  }
}
