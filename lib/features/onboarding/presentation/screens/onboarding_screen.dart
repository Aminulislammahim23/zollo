import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zollo/core/theme/app_colors.dart';
import 'package:zollo/core/theme/app_spacing.dart';
import 'package:zollo/core/theme/app_text.dart';
import 'package:zollo/core/widgets/app_button.dart';
import 'package:zollo/features/auth/domain/providers/auth_provider.dart';
import 'package:zollo/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zollo/features/onboarding/presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Millions of products from trusted sellers',
      description: 'Fashion, electronics, groceries and more, all in one app.',
      icon: Icons.shopping_bag_outlined,
    ),
    OnboardingPageData(
      title: 'Pay the way you like',
      description: 'bKash, Nagad, cards, or cash on delivery. Your payment is protected.',
      icon: Icons.credit_card_outlined,
    ),
    OnboardingPageData(
      title: 'Track every order to your door',
      description:
          'Live updates from packing to delivery, and easy 7-day returns.',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _completing = false;

  List<OnboardingPageData> get _pages => OnboardingScreen.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndNavigate() async {
    if (_completing) return;
    setState(() => _completing = true);
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.l,
            AppSpacing.xl,
            40,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completing ? null : _completeAndNavigate,
                  style: TextButton.styleFrom(textStyle: AppText.bodyStrong),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      OnboardingPage(data: _pages[index]),
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                label: 'Page ${_currentPage + 1} of ${_pages.length}',
                child: Row(
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _currentPage ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton.primary(
                label: isLastPage ? 'Get started' : 'Next',
                loading: _completing,
                onPressed: _onNextPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
