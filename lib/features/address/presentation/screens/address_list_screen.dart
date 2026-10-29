import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/address_card.dart';

/// `/addresses` and `/addresses?select=true`, spec C22.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key, this.isSelecting = false});

  final bool isSelecting;

  Future<bool> _confirmDelete(BuildContext context, Address address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this address?'),
        content: Text('${address.fullName}, ${address.shortArea}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ErrorView.describe(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;
    final addressState = ref.watch(addressListProvider);
    final defaultId = addressState.value
        ?.where((a) => a.isDefault)
        .firstOrNull
        ?.id;

    final Widget body;
    if (!signedIn) {
      body = EmptyState(
        icon: Icons.location_on_outlined,
        title: 'Log in to manage addresses',
        message: 'Save delivery addresses for faster checkout.',
        actionLabel: 'Log in',
        onAction: () => context.push('/login'),
      );
    } else {
      body = addressState.when(
        loading: () => const ShimmerList(itemHeight: 120),
        error: (error, _) => ErrorView(
          title: "Couldn't load your addresses",
          error: error,
          onRetry: () => ref.invalidate(addressListProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add an address to get your orders delivered.',
            );
          }
          return RadioGroup<String>(
            groupValue: defaultId,
            onChanged: (id) =>
                context.pop(addresses.firstWhere((a) => a.id == id)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: addresses.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, i) {
                final address = addresses[i];
                return Dismissible(
                  key: ValueKey(address.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context, address),
                  onDismissed: (_) => _run(context, () async {
                    try {
                      await ref
                          .read(addressListProvider.notifier)
                          .deleteAddress(address.id);
                    } catch (_) {
                      // Bring the dismissed card back.
                      ref.invalidate(addressListProvider);
                      rethrow;
                    }
                  }, 'Address deleted'),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          'Delete',
                          style: AppText.label.withColor(AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  child: AddressCard(
                    address: address,
                    selecting: isSelecting,
                    isSelected: address.id == defaultId,
                    onTap: isSelecting ? () => context.pop(address) : null,
                    onEdit: () => context.push('/edit-address', extra: address),
                    onSetDefault: () => _run(
                      context,
                      () => ref
                          .read(addressListProvider.notifier)
                          .setDefault(address.id),
                      'Default address updated',
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: isSelecting ? 'Choose address' : 'Address book',
        fallbackRoute: '/account',
      ),
      body: body,
      bottomNavigationBar: signedIn
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  AppSpacing.xl,
                ),
                child: AppButton.primary(
                  label: 'Add new address',
                  icon: Icons.add,
                  onPressed: () => context.push('/add-address'),
                ),
              ),
            )
          : null,
    );
  }
}
