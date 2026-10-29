import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.bottom,
    this.fallbackRoute = '/home',
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional widget under the bar (e.g. a [TabBar]).
  final PreferredSizeWidget? bottom;

  /// Where back goes when there is nothing to pop.
  final String fallbackRoute;

  static const double barHeight = 64;

  @override
  Size get preferredSize =>
      Size.fromHeight(barHeight + 1 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Material(
      color: AppColors.surface,
      child: Container(
        padding: EdgeInsets.only(top: topPadding),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: barHeight,
              child: Row(
                children: [
                  SizedBox(width: showBack ? AppSpacing.xs : AppSpacing.l),
                  if (showBack)
                    SizedBox.square(
                      dimension: AppSpacing.tapTarget,
                      child: IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSmall),
                        onPressed: onBack ??
                            () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(fallbackRoute);
                              }
                            },
                      ),
                    ),
                  if (showBack) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppText.caption.withColor(AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
