import '../domain/app_notification.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

// TODO(backend): replace with Supabase implementation
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({DateTime? now}) {
    final t = now ?? DateTime.now();
    _items = [
      AppNotification(
        id: 'n1',
        type: NotificationType.order,
        title: 'Your order is on the way',
        body:
            'The rider picked up your package. Track it live from your orders.',
        createdAt: t.subtract(const Duration(minutes: 25)),
        deepLink: '/order-history?tab=shipped',
      ),
      AppNotification(
        id: 'n2',
        type: NotificationType.promotion,
        title: '11.11 Mega Sale starts tonight',
        body: 'Up to 70% off top brands. Set a reminder so you don\'t miss it.',
        createdAt: t.subtract(const Duration(hours: 3)),
        deepLink: '/products',
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.order,
        title: 'Order confirmed',
        body: 'The seller confirmed your order and is packing it now.',
        createdAt: t.subtract(const Duration(days: 1)),
        read: true,
        deepLink: '/order-history',
      ),
      AppNotification(
        id: 'n4',
        type: NotificationType.promotion,
        title: 'A voucher is waiting for you',
        body: '৳100 off your next order over ৳999. Valid for 3 days.',
        createdAt: t.subtract(const Duration(days: 2)),
        read: true,
        deepLink: '/vouchers',
      ),
    ];
  }

  late List<AppNotification> _items;

  @override
  Future<List<AppNotification>> getNotifications() async =>
      List.unmodifiable(_items);

  @override
  Future<void> markRead(String id) async {
    _items = [for (final n in _items) n.id == id ? n.copyWith(read: true) : n];
  }

  @override
  Future<void> markAllRead() async {
    _items = [for (final n in _items) n.copyWith(read: true)];
  }
}
