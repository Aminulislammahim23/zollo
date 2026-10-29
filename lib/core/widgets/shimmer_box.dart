import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Pulsing placeholder block for loading skeletons.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.tile,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> {
  bool _dim = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _dim = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      label: 'Loading',
      child: AnimatedOpacity(
        opacity: _dim && !disableAnimations ? 0.45 : 1,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOut,
        onEnd: () {
          if (mounted && !disableAnimations) setState(() => _dim = !_dim);
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.placeholder,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// A ready-made list skeleton: [count] rows of card-shaped [ShimmerBox]es.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.count = 4,
    this.itemHeight = 96,
    this.padding = const EdgeInsets.all(AppSpacing.m),
  });

  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (_, _) => ShimmerBox(height: itemHeight, radius: AppRadius.card),
    );
  }
}

/// Two-column product grid skeleton.
class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key, this.count = 4, this.shrinkWrap = false});

  final int count;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.cardGap,
        crossAxisSpacing: AppSpacing.cardGap,
        mainAxisExtent: 240,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const ShimmerBox(height: 240, radius: AppRadius.card),
    );
  }
}
