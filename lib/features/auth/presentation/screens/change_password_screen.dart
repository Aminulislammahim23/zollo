import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_validators.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _signOutOthers = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _new.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            signOutOtherDevices: _signOutOthers,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final text = AuthValidators.message(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.contains('do not match') ? 'Your current password is incorrect.' : text,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Change password', fallbackRoute: '/settings'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.xl),
          children: [
            PasswordField(
              label: 'Current password',
              controller: _current,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot current password?'),
              ),
            ),
            PasswordField(
              label: 'New password',
              controller: _new,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                final rule = AuthValidators.strongPassword(v);
                if (rule != null) return rule;
                if (v == _current.text) return 'Use a password you have not used here';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.l),
            PasswordField(
              label: 'Confirm new password',
              controller: _confirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
              validator: (v) => v != _new.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: AppSpacing.l),
            PasswordRulesChecklist(password: _new.text),
            const SizedBox(height: AppSpacing.s),
            InkWell(
              onTap: () => setState(() => _signOutOthers = !_signOutOthers),
              borderRadius: AppRadius.tileAll,
              child: Row(
                children: [
                  Checkbox(
                    value: _signOutOthers,
                    onChanged: (v) => setState(() => _signOutOthers = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Log out of all other devices',
                      style: AppText.custom(14, FontWeight.w600, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, AppSpacing.m, 20, AppSpacing.xl),
          child: AppButton.primary(label: 'Update password', loading: _saving, onPressed: _submit),
        ),
      ),
    );
  }
}
