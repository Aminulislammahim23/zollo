import '../../products/domain/models/product.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.fromMe,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String text;
  final bool fromMe;
  final DateTime sentAt;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.sellerName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.product,
  });

  final String id;
  final String sellerName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  /// The product the chat is about, shown as a context card.
  final Product? product;

  Conversation copyWith({String? lastMessage, DateTime? lastMessageAt, int? unreadCount, Product? product}) {
    return Conversation(
      id: id,
      sellerName: sellerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      product: product ?? this.product,
    );
  }
}
