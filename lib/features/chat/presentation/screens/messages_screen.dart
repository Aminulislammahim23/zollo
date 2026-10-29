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

/// `/messages`, spec C26a.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Messages', fallbackRoute: '/account'),
      body: async.when(
        loading: () => const ShimmerList(itemHeight: 76),
        error: (error, _) => ErrorView(
          title: "Couldn't load messages",
          error: error,
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (conversations) => conversations.isEmpty
            ? EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No messages yet',
                message: 'Chat with a seller from any product page.',
                actionLabel: 'Browse products',
                onAction: () => context.push('/products'),
              )
            : ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, i) =>
                    _ConversationRow(conversation: conversations[i]),
              ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;
    return InkWell(
      onTap: () => context.push('/messages/${c.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: AppRadius.cardAll,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.rowTitle,
                        ),
                      ),
                      Text(
                        formatRelative(c.lastMessageAt),
                        style: AppText.timestamp.withColor(AppColors.hint),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta
                              .withWeight(
                                unread ? FontWeight.w700 : FontWeight.w500,
                              )
                              .withColor(
                                unread ? AppColors.ink : AppColors.muted,
                              ),
                        ),
                      ),
                      if (unread)
                        Container(
                          height: 20,
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          margin: const EdgeInsets.only(left: AppSpacing.s),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.chipAll,
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            semanticsLabel: '${c.unreadCount} unread',
                            style: AppText.tag.withColor(AppColors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
