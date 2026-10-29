import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/review.dart';
import '../../domain/review_summary.dart';
import '../../providers/review_providers.dart';
import '../widgets/rating_stars.dart';

/// `/product-reviews` (extra: Product), spec C20.
class ProductReviewsScreen extends ConsumerWidget {
  const ProductReviewsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final canReview = ref.watch(canUserReviewProvider(product.id)).value ?? false;

    return Scaffold(
      appBar: const AppTopBar(title: 'Ratings & reviews'),
      body: reviewsAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorView(
          title: "Couldn't load reviews",
          error: error,
          onRetry: () => ref.invalidate(productReviewsProvider(product.id)),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet.',
              message: 'Be the first to review it.',
              actionLabel: canReview ? 'Write a review' : null,
              onAction: () => context.push('/write-review', extra: product),
            );
          }
          final summary = ReviewSummary.from(reviews);
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(productReviewsProvider(product.id)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: reviews.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReviewSummaryCard(summary: summary),
                      if (canReview) ...[
                        const SizedBox(height: AppSpacing.cardGap),
                        AppButton.outline(
                          label: 'Write a review',
                          icon: Icons.edit_outlined,
                          onPressed: () => context.push('/write-review', extra: product),
                        ),
                      ],
                    ],
                  );
                }
                return ReviewCard(review: reviews[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Row(
        children: [
          Column(
            children: [
              Text(summary.average.toStringAsFixed(1), style: AppText.custom(32, FontWeight.w800)),
              RatingStars(rating: summary.average),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${summary.count} ${summary.count == 1 ? 'rating' : 'ratings'}',
                style: AppText.caption.withColor(AppColors.muted),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              children: [
                for (var stars = 5; stars >= 1; stars--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Semantics(
                      label: '$stars stars: ${summary.countFor(stars)}',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          SizedBox(width: 22, child: Text('$stars★', style: AppText.caption)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: summary.count == 0 ? 0 : summary.countFor(stars) / summary.count,
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                color: AppColors.star,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${summary.countFor(stars)}',
                              textAlign: TextAlign.end,
                              style: AppText.caption.withColor(AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.rating),
              const Spacer(),
              Text(formatDate(review.createdAt), style: AppText.caption.withColor(AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Verified buyer', style: AppText.custom(12, FontWeight.w700, color: AppColors.primary)),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: AppText.custom(14, FontWeight.w500, color: AppColors.inkSoft, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
