import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_validators.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _backToLogin() => context.canPop() ? context.pop() : context.go('/login');

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(_email.text);
      if (!mounted) return;
      setState(() => _sentTo = _email.text.trim());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthValidators.message(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sentTo != null) {
      return AuthScaffold(
        showBack: true,
        content: [
          const AuthIconTile(icon: Icons.mark_email_unread_outlined),
          AuthHeading(
            title: 'Check your inbox',
            subtitle: 'We sent a reset link to $_sentTo.',
          ),
          AppButton.primary(label: 'Back to log in', onPressed: _backToLogin),
        ],
      );
    }

    return AuthScaffold(
      showBack: true,
      content: [
        const AuthIconTile(icon: Icons.lock_outline),
        const AuthHeading(
          title: 'Forgot your password?',
          subtitle: "Enter the email on your account. We'll send you a link to reset it.",
        ),
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: AuthValidators.email,
            onSubmitted: (_) => _submit(),
          ),
        ),
        AppButton.primary(label: 'Send reset link', loading: _sending, onPressed: _submit),
      ],
      footer: [
        AuthLinkText(prefix: 'Remembered it?', link: 'Back to log in', onTap: _backToLogin),
      ],
    );
  }
}
