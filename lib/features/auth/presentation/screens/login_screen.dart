import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_validators.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _keepLoggedIn = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;

    if (ok) {
      context.go('/home');
      return;
    }
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AuthValidators.message(error ?? 'Could not log in.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      content: [
        const AuthHeading(
          title: 'Welcome back',
          subtitle: 'Log in to track orders and check out faster.',
        ),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: AppSpacing.l),
                PasswordField(
                  controller: _password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
                        borderRadius: AppRadius.tileAll,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _keepLoggedIn,
                              onChanged: (v) => setState(() => _keepLoggedIn = v ?? true),
                            ),
                            Flexible(
                              child: Text(
                                'Keep me logged in',
                                style: AppText.custom(13, FontWeight.w500, color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppButton.primary(label: 'Log in', loading: isLoading, onPressed: _submit),
        if (AppConstants.showSocialLogin) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Text(
                  'or continue with',
                  style: AppText.custom(13, FontWeight.w500, color: AppColors.muted),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          Row(
            children: [
              Expanded(child: AppButton.outline(label: 'Google', height: 50, onPressed: () {})),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: AppButton.outline(label: 'Facebook', height: 50, onPressed: () {})),
            ],
          ),
        ],
      ],
      footer: [
        AuthLinkText(
          prefix: 'New to zollo?',
          link: 'Create an account',
          onTap: () => context.push('/signup'),
        ),
        TextButton(
          onPressed: () => context.go('/home'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.muted,
            textStyle: AppText.custom(14, FontWeight.w700),
          ),
          child: const Text('Continue as guest'),
        ),
      ],
    );
  }
}
