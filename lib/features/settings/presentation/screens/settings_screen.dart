import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/support.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/settings_repository.dart';
import '../providers/settings_providers.dart';

/// `/settings`, spec C27.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't log out. ${ErrorView.describe(state.error)}")),
      );
      return;
    }
    ref.read(cartProvider.notifier).clearCart();
    context.go('/login');
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This removes your profile, addresses, wishlist and order history. It cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // TODO(backend): call a delete-account Edge Function instead.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contact support to delete your account'),
        content: const Text(
          "For your security, account deletion is handled by our support team. "
          "Email ${AppConstants.supportEmail} from your account's email address.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              contactSupport(context, subject: 'Delete my account');
            },
            child: const Text('Email support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final prefs = ref.watch(notificationPrefsProvider);
    final signedIn = ref.watch(currentUserProvider) != null;
    final loggingOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: const AppTopBar(title: 'Settings', fallbackRoute: '/account'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Caption('LANGUAGE'),
                const SizedBox(height: AppSpacing.m),
                _SegmentedControl(
                  value: locale,
                  options: const {'en': 'English', 'bn': 'বাংলা'},
                  onChanged: (code) => ref.read(localeProvider.notifier).set(code),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Caption('NOTIFICATIONS'),
                const SizedBox(height: AppSpacing.xs),
                for (final p in NotificationPref.values)
                  MergeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: AppText.bodyStrong),
                                Text(p.note, style: AppText.caption.withColor(AppColors.muted)),
                              ],
                            ),
                          ),
                          Switch(
                            value: prefs[p] ?? true,
                            onChanged: (v) => ref.read(notificationPrefsProvider.notifier).set(p, v),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          InfoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (signedIn)
                  _LinkRow(label: 'Change password', onTap: () => context.push('/settings/change-password')),
                _LinkRow(
                  label: 'Privacy policy',
                  onTap: () => openExternalUrl(context, AppConstants.privacyPolicyUrl),
                ),
                _LinkRow(
                  label: 'Terms of use',
                  onTap: () => openExternalUrl(context, AppConstants.termsUrl),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (signedIn) ...[
            AppButton.danger(
              label: 'Log out',
              height: 50,
              loading: loggingOut,
              onPressed: () => _logOut(context, ref),
            ),
            const SizedBox(height: AppSpacing.s),
            Center(
              child: TextButton(
                onPressed: () => _deleteAccount(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                child: const Text('Delete my account'),
              ),
            ),
          ] else
            AppButton.primary(label: 'Log in', onPressed: () => context.push('/login')),
          const SizedBox(height: AppSpacing.s),
          Center(
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: AppText.custom(11, FontWeight.w500, color: AppColors.hint),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.custom(12, FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.value, required this.options, required this.onChanged});

  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(color: AppColors.surfaceAlt, borderRadius: AppRadius.buttonAll),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == value,
                child: Material(
                  color: entry.key == value ? AppColors.surface : AppColors.transparent,
                  borderRadius: AppRadius.tileAll,
                  child: InkWell(
                    borderRadius: AppRadius.tileAll,
                    onTap: () => onChanged(entry.key),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Center(
                        child: Text(
                          entry.value,
                          style: AppText.custom(
                            14,
                            entry.key == value ? FontWeight.w800 : FontWeight.w600,
                            color: entry.key == value ? AppColors.primary : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap, this.last = false});

  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.custom(14, FontWeight.w600))),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.hint),
          ],
        ),
      ),
    );
  }
}
