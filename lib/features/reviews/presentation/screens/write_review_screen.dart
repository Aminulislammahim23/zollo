import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../products/domain/models/product.dart';
import '../../providers/review_providers.dart';
import '../widgets/rating_stars.dart';

/// `/write-review` (extra: Product), spec C21.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a star rating.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            productId: widget.product.id,
            rating: _rating,
            comment: _comment.text,
          );
      ref.invalidate(productReviewsProvider(widget.product.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your review has been posted.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorView.describe(error))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: const AppTopBar(title: 'Write a review'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          InfoCard(
            child: Row(
              children: [
                AppNetworkImage(url: product.imageUrl, width: 56, height: 56, borderRadius: AppRadius.tileAll),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.custom(13, FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              children: [
                Text('How would you rate it?', style: AppText.custom(15, FontWeight.w800)),
                const SizedBox(height: 10),
                RatingStars(
                  rating: _rating,
                  size: 36,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 10),
                Text(
                  _rating == 0 ? 'Tap a star' : RatingStars.labels[_rating - 1],
                  style: AppText.custom(14, FontWeight.w700, color: _rating == 0 ? AppColors.hint : AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          InfoCard(
            child: AppTextField(
              label: 'Your review',
              controller: _comment,
              hint: 'What did you like or dislike? How was the quality?',
              maxLines: 5,
              minLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.m),
        child: SafeArea(
          top: false,
          child: AppButton.primary(label: 'Submit review', loading: _submitting, onPressed: _submit),
        ),
      ),
    );
  }
}
