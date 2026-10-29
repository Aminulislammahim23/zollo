import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zollo/core/widgets/zollo_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Duration splashDelay;

  const SplashScreen({
    super.key,
    this.splashDelay = const Duration(milliseconds: 1500),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F8FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const ZolloLogo(size: 96, showText: true),
            const SizedBox(height: 16),
            Text(
              'Your Ultimate Marketplace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006B54)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
