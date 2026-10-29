import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FakeNotificationRepository();
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<List<AppNotification>> build() => _repo.getNotifications();

  Future<void> markRead(String id) async {
    final current = state.value ?? const [];
    state = AsyncData([for (final n in current) n.id == id ? n.copyWith(read: true) : n]);
    await _repo.markRead(id);
  }

  Future<void> markAllRead() async {
    final current = state.value ?? const [];
    state = AsyncData([for (final n in current) n.copyWith(read: true)]);
    await _repo.markAllRead();
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).value ?? const [];
  return items.where((n) => !n.read).length;
});
