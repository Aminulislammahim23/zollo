import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../orders/presentation/widgets/order_thumbnail.dart';
import '../../domain/return_request.dart';
import '../providers/return_providers.dart';

/// `/return-request` (extra: OrderModel), spec C28.
class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _details = TextEditingController();
  late final Set<String> _selected = {
    if (widget.order.items.length == 1) widget.order.items.first.productId,
  };
  ReturnReason? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      _snack('Choose at least one item to return.');
      return;
    }
    if (_reason == null) {
      _snack('Tell us why you are returning it.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(returnRepositoryProvider)
          .submit(
            ReturnRequest(
              orderId: widget.order.id,
              productIds: _selected.toList(),
              reason: _reason!,
              details: _details.text.trim(),
            ),
          );
      if (!mounted) return;
      _snack(
        "Return requested. We'll email you the pickup details within 24 hours.",
      );
      context.pop();
    } catch (error) {
      _snack(ErrorView.describe(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final windowEnds = order.createdAt.add(
      const Duration(
        days: AppConstants.returnWindowDays + AppConstants.maxDeliveryDays,
      ),
    );
    final multiple = order.items.length > 1;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Request a return',
        fallbackRoute: '/order-history',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (multiple) ...[
                  Text('Which items?', style: AppText.cardTitle),
                  const SizedBox(height: AppSpacing.s),
                ],
                for (final item in order.items)
                  InkWell(
                    onTap: multiple
                        ? () => setState(() {
                            _selected.contains(item.productId)
                                ? _selected.remove(item.productId)
                                : _selected.add(item.productId);
                          })
                        : null,
                    borderRadius: AppRadius.tileAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          if (multiple)
                            Checkbox(
                              value: _selected.contains(item.productId),
                              onChanged: (v) => setState(() {
                                v == true
                                    ? _selected.add(item.productId)
                                    : _selected.remove(item.productId);
                              }),
                            ),
                          OrderThumbnail(
                            productId: item.productId,
                            imageUrl: item.imageUrl,
                            size: 56,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatTaka(item.price)} · return window ends ${formatDate(windowEnds)}',
                                  style: AppText.meta.withColor(
                                    AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Why are you returning it?', style: AppText.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                RadioGroup<ReturnReason>(
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v),
                  child: Column(
                    children: [
                      for (final r in ReturnReason.values)
                        InkWell(
                          onTap: () => setState(() => _reason = r),
                          borderRadius: AppRadius.tileAll,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Row(
                              children: [
                                Radio<ReturnReason>(value: r),
                                Expanded(
                                  child: Text(
                                    r.label,
                                    style: AppText.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Tell us more',
                  controller: _details,
                  hint: 'What happened? Any detail helps.',
                  maxLines: 3,
                  minLines: 3,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Tooltip(
                      message: 'Adding photos is coming soon',
                      child: DashedBorder(
                        color: AppColors.border,
                        radius: AppRadius.tile,
                        child: const SizedBox.square(
                          dimension: 56,
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.muted,
                            size: AppSpacing.iconInline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'Photos help us approve your return faster',
                        style: AppText.meta.withColor(AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: AppSpacing.iconInline,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund to bKash or bank',
                        style: AppText.bodyStrong,
                      ),
                      Text(
                        'Paid with cash on delivery',
                        style: AppText.caption.withColor(AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.m,
        ),
        child: SafeArea(
          top: false,
          child: AppButton.primary(
            label: 'Submit return request',
            loading: _submitting,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
