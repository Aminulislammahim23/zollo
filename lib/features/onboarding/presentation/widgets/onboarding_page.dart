import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The panel is 300 high by spec, but shrinks on short screens or at
        // large text scales so the copy never overflows.
        final panelHeight = (constraints.maxHeight * 0.55).clamp(160.0, 300.0);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: panelHeight,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  data.icon,
                  size: panelHeight * 0.4,
                  color: AppColors.primary,
                  semanticLabel: data.title,
                ),
              ),
              const SizedBox(height: 28),
              Text(data.title, style: AppText.headline),
              const SizedBox(height: 12),
              Text(
                data.description,
                style: AppText.body.withColor(AppColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}
