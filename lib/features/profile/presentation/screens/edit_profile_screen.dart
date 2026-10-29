import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/auth_validators.dart';
import '../../../auth/domain/providers/auth_provider.dart';

/// `/edit-profile`, spec C18.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.displayName ?? '');
    final phone = user?.phoneNumber;
    _phone = TextEditingController(
      text: phone == null ? '' : PhoneField.normalize(phone),
    );
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final phone = _phone.text.trim();
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: _name.text,
          phone: phone.isEmpty ? '' : PhoneField.toE164(phone),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't save your profile. ${AuthValidators.message(state.error!)}",
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    context.canPop() ? context.pop() : context.go('/account');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: const AppTopBar(
          title: 'Edit profile',
          fallbackRoute: '/account',
        ),
        body: EmptyState(
          icon: Icons.person_outline,
          title: 'Log in to edit your profile',
          actionLabel: 'Log in',
          onAction: () => context.push('/login'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Edit profile', fallbackRoute: '/account'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 20,
          ),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initial,
                  style: AppText.ratingAverage.withColor(AppColors.primary),
                ),
              ),
            ),
            const Center(
              child: Tooltip(
                message: 'Profile photos are coming soon',
                // TODO(backend): upload avatars to Supabase Storage.
                child: TextButton(onPressed: null, child: Text('Change photo')),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            AppTextField(
              label: 'Full name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.fullName,
            ),
            const SizedBox(height: AppSpacing.l),
            PhoneField(
              controller: _phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.l),
            AppTextField(
              label: 'Email',
              controller: _email,
              readOnly: true,
              fillColor: AppColors.background,
              labelTrailing: user.isEmailVerified
                  ? Text(
                      'Verified',
                      style: AppText.captionHeavy.withColor(AppColors.primary),
                    )
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.m,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: AppButton.primary(
            label: 'Save changes',
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
