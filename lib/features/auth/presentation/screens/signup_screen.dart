import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_validators.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _open(AppConstants.termsUrl);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _open(AppConstants.privacyPolicyUrl);

  String? _confirmationSentTo;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final response = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
          // Required and validated above; saved in metadata as +8801XXXXXXXXX.
          phone: PhoneField.toE164(_phone.text.trim()),
        );
    if (!mounted) return;

    if (response == null) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthValidators.message(error ?? 'Could not create your account.'),
          ),
        ),
      );
      return;
    }

    if (response.session == null) {
      setState(() => _confirmationSentTo = _email.text.trim());
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmationSentTo != null) {
      return AuthScaffold(
        content: [
          const AuthIconTile(
            icon: Icons.mark_email_unread_outlined,
            circle: true,
          ),
          AuthHeading(
            title: 'Check your email',
            subtitle: 'We sent a confirmation link to $_confirmationSentTo.',
          ),
          AppButton.primary(
            label: 'Back to log in',
            onPressed: () => context.go('/login'),
          ),
        ],
      );
    }

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final linkStyle = AppText.label.withColor(AppColors.primary);

    return AuthScaffold(
      gap: 20,
      content: [
        const AuthHeading(
          title: 'Create your account',
          subtitle: 'Shop, track orders and save your favourites.',
        ),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Your name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: AuthValidators.fullName,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 14),
                PhoneField(
                  label: 'Phone',
                  controller: _phone,
                  required: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  hint: 'At least 8 characters',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 10),
                PasswordStrengthBar(password: _password.text),
                const SizedBox(height: 14),
                FormField<bool>(
                  initialValue: false,
                  validator: (v) =>
                      v == true ? null : 'Please accept the terms to continue',
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: field.value ?? false,
                            onChanged: (v) => field.didChange(v),
                            side: BorderSide(
                              color: field.hasError
                                  ? AppColors.error
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppText.meta.withColor(AppColors.muted),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of use',
                                    style: linkStyle,
                                    recognizer: _termsTap,
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy policy',
                                    style: linkStyle,
                                    recognizer: _privacyTap,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.m),
                          child: Text(
                            field.errorText!,
                            style: AppText.caption.withColor(AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppButton.primary(
          label: 'Create account',
          loading: isLoading,
          onPressed: _submit,
        ),
      ],
      footer: [
        AuthLinkText(
          prefix: 'Already have an account?',
          link: 'Log in',
          onTap: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ],
    );
  }
}
