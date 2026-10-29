import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FakeChatRepository();
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).watchConversations();
});

final conversationProvider = Provider.family<Conversation?, String>((ref, id) {
  final list = ref.watch(conversationsProvider).value ?? const <Conversation>[];
  return list.where((c) => c.id == id).firstOrNull;
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});
