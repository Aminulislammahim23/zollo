import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/voucher.dart';
import '../providers/voucher_providers.dart';

/// `/vouchers`, spec C24.
class VouchersScreen extends ConsumerStatefulWidget {
  const VouchersScreen({super.key});

  @override
  ConsumerState<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends ConsumerState<VouchersScreen> {
  final _code = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    FocusScope.of(context).unfocus();
    setState(() => _adding = true);
    try {
      final voucher = await ref.read(vouchersProvider.notifier).redeem(_code.text);
      _code.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added: ${voucher.title}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorView.describe(error))));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vouchersAsync = ref.watch(vouchersProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'My vouchers', fallbackRoute: '/account'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          InfoCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _code,
                    hint: 'Enter a voucher code',
                    height: 44,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      _UpperCaseFormatter(),
                    ],
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                AppButton.primary(
                  label: 'Add',
                  size: AppButtonSize.small,
                  fullWidth: false,
                  height: 44,
                  loading: _adding,
                  onPressed: _add,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          ...vouchersAsync.when(
            loading: () => [const ShimmerBox(height: 96, radius: AppRadius.card)],
            error: (error, _) => [
              SizedBox(
                height: 300,
                child: ErrorView(
                  title: "Couldn't load vouchers",
                  error: error,
                  onRetry: () => ref.invalidate(vouchersProvider),
                ),
              ),
            ],
            data: (vouchers) => vouchers.isEmpty
                ? [
                    const SizedBox(
                      height: 300,
                      child: EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: 'No vouchers yet',
                        message: 'Vouchers you collect will appear here.',
                      ),
                    ),
                  ]
                : [
                    for (final v in vouchers) ...[
                      _VoucherTicket(voucher: v),
                      const SizedBox(height: AppSpacing.cardGap),
                    ],
                  ],
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class _VoucherTicket extends StatelessWidget {
  const _VoucherTicket({required this.voucher});

  final Voucher voucher;

  String get _expiry {
    final days = voucher.expiresAt.difference(DateTime.now()).inDays;
    if (voucher.isExpired) return 'Expired';
    if (days <= 0) return 'Expires today';
    if (days <= 7) return 'Expires in $days ${days == 1 ? 'day' : 'days'}';
    return 'Valid until ${formatDate(voucher.expiresAt)}';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.cardAll,
      child: Container(
        color: AppColors.surface,
        constraints: const BoxConstraints(minHeight: 96),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                color: AppColors.deep,
                padding: const EdgeInsets.all(AppSpacing.s),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        voucher.amountLabel,
                        style: AppText.custom(20, FontWeight.w800, color: AppColors.accent),
                      ),
                    ),
                    Text('OFF', style: AppText.custom(11, FontWeight.w700, color: AppColors.white)),
                  ],
                ),
              ),
              const DashedVerticalLine(color: AppColors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.title, style: AppText.custom(14, FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(voucher.rule, style: AppText.custom(13, FontWeight.w500, color: AppColors.muted)),
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _expiry,
                              style: AppText.custom(12, FontWeight.w700, color: AppColors.warning),
                            ),
                          ),
                          AppButton.outline(
                            label: 'Use',
                            size: AppButtonSize.small,
                            fullWidth: false,
                            height: 32,
                            onPressed: voucher.isExpired
                                ? null
                                : () => ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Code ${voucher.code} saved. Applying vouchers at checkout is coming soon.',
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
