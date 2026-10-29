import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';

class Campaign {
  const Campaign({
    required this.label,
    required this.title,
    required this.cta,
    required this.route,
  });

  final String label;
  final String title;
  final String cta;
  final String route;
}

/// Swipeable campaign banners. Content is static until a campaigns table exists.
class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  static const campaigns = [
    Campaign(
      label: '11.11 MEGA SALE',
      title: 'Up to 70% off on top brands',
      cta: 'Shop now',
      route: '/products',
    ),
    Campaign(
      label: 'FREE DELIVERY',
      title: 'Free delivery on your first order',
      cta: 'Start shopping',
      route: '/products',
    ),
    Campaign(
      label: 'NEW ARRIVALS',
      title: 'Fresh picks for the season',
      cta: 'Explore',
      route: '/categories',
    ),
  ];

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = PromoBanner.campaigns;
    final height =
        140 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: campaigns.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: _CampaignCard(campaign: campaigns[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Banner ${_page + 1} of ${campaigns.length}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < campaigns.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.deep,
        borderRadius: AppRadius.bannerAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.label,
            style: AppText.captionStrong.copyWith(
              color: AppColors.accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Text(
              campaign.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.campaignTitle.copyWith(
                color: AppColors.white,
                height: 1.15,
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.accent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => context.push(campaign.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: AppSpacing.s,
                ),
                child: Text(
                  campaign.cta,
                  style: AppText.label.withColor(AppColors.onAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
