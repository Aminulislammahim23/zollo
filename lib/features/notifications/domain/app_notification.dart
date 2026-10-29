enum NotificationType { order, promotion }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.deepLink,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// In-app route opened on tap, e.g. `/order-history`.
  final String? deepLink;

  /// Two-letter tile tag.
  String get tag => type == NotificationType.order ? 'OR' : '%';

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        deepLink: deepLink,
      );
}
