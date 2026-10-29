import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../domain/auth_validators.dart';

/// White auth page: padding 24, optional back button, content that scrolls
/// when needed and a footer pinned to the bottom when there is room.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.content,
    this.footer = const [],
    this.gap = AppSpacing.xl,
    this.showBack,
  });

  final List<Widget> content;
  final List<Widget> footer;
  final double gap;

  /// Defaults to "only when the screen can pop".
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? context.canPop();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.xl * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canPop)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: const Offset(-12, 0),
                          child: IconButton(
                            tooltip: 'Back',
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: AppSpacing.iconSmall,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                    for (var i = 0; i < content.length; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      content[i],
                    ],
                    if (footer.isNotEmpty) ...[
                      const Spacer(),
                      SizedBox(height: gap),
                      ...footer,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title + subtitle block at the top of every auth page.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AppText.display)),
        const SizedBox(height: AppSpacing.s),
        Text(subtitle, style: AppText.body.withColor(AppColors.muted)),
      ],
    );
  }
}

/// "New to zollo? **Create an account**" style line with a tappable link.
class AuthLinkText extends StatefulWidget {
  const AuthLinkText({
    super.key,
    required this.prefix,
    required this.link,
    required this.onTap,
  });

  final String prefix;
  final String link;
  final VoidCallback onTap;

  @override
  State<AuthLinkText> createState() => _AuthLinkTextState();
}

class _AuthLinkTextState extends State<AuthLinkText> {
  late final TapGestureRecognizer _recognizer = TapGestureRecognizer()
    ..onTap = widget.onTap;

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.prefix} ${widget.link}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.buttonAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.tapTarget),
          child: Center(
            child: Text.rich(
              TextSpan(
                style: AppText.bodyMedium.withColor(AppColors.muted),
                children: [
                  TextSpan(text: '${widget.prefix} '),
                  TextSpan(
                    text: widget.link,
                    recognizer: _recognizer,
                    style: AppText.rowTitle.withColor(AppColors.primary),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Large icon in a rounded [AppColors.primaryTint] tile (forgot password).
class AuthIconTile extends StatelessWidget {
  const AuthIconTile({super.key, required this.icon, this.circle = false});

  final IconData icon;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 30, color: AppColors.primary),
      ),
    );
  }
}

/// Live checklist: 8 characters, a number, an uppercase letter.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('At least 8 characters', AuthValidators.hasMinLength(password)),
      ('One number', AuthValidators.hasNumber(password)),
      ('One uppercase letter', AuthValidators.hasUppercase(password)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, met) in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              label: '$label, ${met ? 'met' : 'not met'}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    met ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: met ? AppColors.primary : AppColors.hint,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.meta.withColor(AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 4-segment password strength bar.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    final score = AuthValidators.strength(password);
    return Semantics(
      label: score == 0
          ? 'Password strength'
          : 'Password strength: ${_labels[score]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
