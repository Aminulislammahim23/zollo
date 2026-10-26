import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';

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
    // Artificial minimum delay for smooth branding experience & logo display
    final minDelay = Future.delayed(widget.splashDelay);

    // Read onboarding status
    bool isOnboardingCompleted = false;
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      isOnboardingCompleted = await repository.isOnboardingCompleted();
    } catch (_) {
      // Fallback if SharedPreferences fails
      isOnboardingCompleted = false;
    }

    // Wait for minimum splash delay
    await minDelay;

    if (!mounted) return;

    // Determine target route based on onboarding & authentication state
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
            // Brand Logo Widget
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4BDB), Color(0xFF006B54)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'zollo',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF5B4BDB),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline / Subtitle
            Text(
              'Your Ultimate Marketplace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            // Loading Indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B4BDB)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
