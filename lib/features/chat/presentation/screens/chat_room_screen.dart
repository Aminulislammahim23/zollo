import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_providers.dart';

/// `/messages/:conversationId`, spec C26b.
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    Future.microtask(() => ref.read(chatRepositoryProvider).markRead(widget.conversationId));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(widget.conversationId, text);
    } catch (error) {
      if (!mounted) return;
      _input.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message not sent. ${ErrorView.describe(error)}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final product = conversation?.product;
    final canSend = _input.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppTopBar(
        title: conversation?.sellerName ?? 'Chat',
        subtitle: 'Usually replies within 1 hour',
        subtitleStyle: AppText.custom(12, FontWeight.w700, color: AppColors.primary),
        fallbackRoute: '/messages',
      ),
      body: Column(
        children: [
          if (product != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
              child: InfoCard(
                radius: AppRadius.button,
                padding: const EdgeInsets.all(10),
                onTap: () => context.push('/product-details', extra: product),
                child: Row(
                  children: [
                    AppNetworkImage(url: product.imageUrl, width: 44, height: 44, borderRadius: AppRadius.tileAll),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(12, FontWeight.w700),
                          ),
                          Text(
                            formatTaka(product.price),
                            style: AppText.custom(12, FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.hint),
                  ],
                ),
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                title: "Couldn't load this chat",
                error: error,
                onRetry: () => ref.invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (messages) => messages.isEmpty
                  ? const EmptyState(
                      icon: Icons.waving_hand_outlined,
                      title: 'Say hello',
                      message: 'Ask about sizes, stock or delivery. Sellers usually reply within an hour.',
                    )
                  : _MessageList(messages: messages),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.m,
              10,
              AppSpacing.m,
              MediaQuery.paddingOf(context).bottom + 20,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Send a photo (coming soon)',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sending photos is coming soon.')),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    minimumSize: const Size.square(44),
                  ),
                  icon: const Icon(Icons.photo_outlined, size: AppSpacing.iconInline, color: AppColors.inkSoft),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: AppText.custom(14, FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      constraints: const BoxConstraints(minHeight: 44),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: AppColors.primary, width: AppBorders.selected),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  tooltip: 'Send',
                  onPressed: canSend ? _send : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.divider,
                    minimumSize: const Size.square(44),
                  ),
                  icon: Icon(Icons.send_rounded, size: AppSpacing.iconInline,
                      color: canSend ? AppColors.white : AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<ChatMessage> messages;

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatDateLong(date);
  }

  @override
  Widget build(BuildContext context) {
    // Newest at the bottom; the list is reversed so it opens scrolled down.
    final reversed = messages.reversed.toList();
    return Container(
      color: AppColors.background,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: reversed.length,
        itemBuilder: (context, i) {
          final m = reversed[i];
          final older = i + 1 < reversed.length ? reversed[i + 1] : null;
          final showDay = older == null || _dayLabel(older.sentAt) != _dayLabel(m.sentAt);
          return Column(
            children: [
              if (showDay)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Text(_dayLabel(m.sentAt), style: AppText.custom(11, FontWeight.w500, color: AppColors.hint)),
                ),
              _Bubble(message: m),
            ],
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    const r = Radius.circular(16);
    const tail = Radius.circular(4);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary : AppColors.surface,
              borderRadius: mine
                  ? const BorderRadius.only(topLeft: r, topRight: r, bottomLeft: r, bottomRight: tail)
                  : const BorderRadius.only(topLeft: r, topRight: r, bottomLeft: tail, bottomRight: r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: AppText.custom(14, FontWeight.w500, color: mine ? AppColors.white : AppColors.ink, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTime(message.sentAt),
                  style: AppText.custom(10, FontWeight.w500, color: mine ? AppColors.onPrimaryMuted : AppColors.hint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
