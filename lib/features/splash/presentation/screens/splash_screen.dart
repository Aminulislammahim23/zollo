import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/core/theme/app_colors.dart';
import 'package:zollo/core/theme/app_spacing.dart';
import 'package:zollo/core/theme/app_text.dart';
import 'package:zollo/core/widgets/zollo_wordmark.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Duration splashDelay;

  const SplashScreen({
    super.key,
    this.splashDelay = const Duration(milliseconds: 1500),
  });

  static const String tagline =
      'Everything you need, delivered across Bangladesh';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: ZolloWordmark.introDuration,
  );

  /// Tagline fades in once the last glyph has landed (~950 ms).
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    final minDelay = Future.delayed(widget.splashDelay);

    bool isOnboardingCompleted = false;
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      isOnboardingCompleted = await repository.isOnboardingCompleted();
    } catch (_) {
      isOnboardingCompleted = false;
    }

    await minDelay;

    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);

    if (!isOnboardingCompleted) {
      context.go('/onboarding');
    } else if (currentUser != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onMuted = AppColors.onPrimaryMuted;
    return Scaffold(
      backgroundColor: AppColors.splashMid,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.splashStart,
              AppColors.splashMid,
              AppColors.splashEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ZolloWordmark(animation: _intro),
                        const SizedBox(height: AppSpacing.l),
                        FadeTransition(
                          opacity: _taglineFade,
                          child: Text(
                            SplashScreen.tagline,
                            textAlign: TextAlign.center,
                            style: AppText.bodyPlain.copyWith(
                              color: onMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'English · বাংলা',
                  style: AppText.caption.withColor(onMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
