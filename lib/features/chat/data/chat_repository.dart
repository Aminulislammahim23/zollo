import 'dart:async';

import '../../products/domain/models/product.dart';
import '../domain/chat_models.dart';

/// Shaped for Supabase Realtime: both lists are streams that emit the full
/// current state on listen and again after every change.
abstract interface class ChatRepository {
  Stream<List<Conversation>> watchConversations();

  Stream<List<ChatMessage>> watchMessages(String conversationId);

  Future<void> sendMessage(String conversationId, String text);

  Future<void> markRead(String conversationId);

  /// Finds or starts the conversation with the seller of [product].
  Future<Conversation> conversationForProduct(Product product);
}

// TODO(backend): replace with Supabase implementation
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({DateTime? now}) {
    final t = now ?? DateTime.now();
    _conversations = [
      Conversation(
        id: 'c1',
        sellerName: 'Gadget Hub BD',
        lastMessage: 'Yes, it comes with a 1-year warranty.',
        lastMessageAt: t.subtract(const Duration(minutes: 12)),
        unreadCount: 1,
      ),
      Conversation(
        id: 'c2',
        sellerName: 'Aarong Style House',
        lastMessage: 'Your parcel was handed to the courier today.',
        lastMessageAt: t.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];
    _messages = {
      'c1': [
        ChatMessage(
          id: 'm1',
          conversationId: 'c1',
          text: 'Hi! Does this have a warranty?',
          fromMe: true,
          sentAt: t.subtract(const Duration(minutes: 20)),
        ),
        ChatMessage(
          id: 'm2',
          conversationId: 'c1',
          text: 'Yes, it comes with a 1-year warranty.',
          fromMe: false,
          sentAt: t.subtract(const Duration(minutes: 12)),
        ),
      ],
      'c2': [
        ChatMessage(
          id: 'm3',
          conversationId: 'c2',
          text: 'When will my order ship?',
          fromMe: true,
          sentAt: t.subtract(const Duration(days: 1, hours: 4)),
        ),
        ChatMessage(
          id: 'm4',
          conversationId: 'c2',
          text: 'Your parcel was handed to the courier today.',
          fromMe: false,
          sentAt: t.subtract(const Duration(days: 1, hours: 2)),
        ),
      ],
    };
  }

  late List<Conversation> _conversations;
  late Map<String, List<ChatMessage>> _messages;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 100;

  List<Conversation> get _sorted =>
      [..._conversations]
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

  /// Emits [snapshot] on listen and after every change, like a realtime query.
  Stream<T> _watch<T>(T Function() snapshot) {
    StreamSubscription<void>? sub;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(snapshot());
        sub = _changes.stream.listen((_) => controller.add(snapshot()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<List<Conversation>> watchConversations() => _watch(() => _sorted);

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) => _watch(
    () => List<ChatMessage>.unmodifiable(_messages[conversationId] ?? const []),
  );

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final message = ChatMessage(
      id: 'm${_nextId++}',
      conversationId: conversationId,
      text: trimmed,
      fromMe: true,
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);
    _conversations = [
      for (final c in _conversations)
        c.id == conversationId
            ? c.copyWith(lastMessage: trimmed, lastMessageAt: message.sentAt)
            : c,
    ];
    _changes.add(null);
  }

  @override
  Future<void> markRead(String conversationId) async {
    _conversations = [
      for (final c in _conversations)
        c.id == conversationId ? c.copyWith(unreadCount: 0) : c,
    ];
    _changes.add(null);
  }

  @override
  Future<Conversation> conversationForProduct(Product product) async {
    final existing = _conversations
        .where((c) => c.product?.id == product.id)
        .firstOrNull;
    if (existing != null) return existing;

    final conversation = Conversation(
      id: 'c${_nextId++}',
      sellerName: 'zollo seller',
      lastMessage: 'Ask the seller about ${product.title}',
      lastMessageAt: DateTime.now(),
      product: product,
    );
    _conversations = [conversation, ..._conversations];
    _messages[conversation.id] = [];
    _changes.add(null);
    return conversation;
  }
}
