import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimController;
  late Animation<double> _iconScaleAnim;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to SnackHack!',
      description:
          'A playful, healthy eating adventure. No calorie counting, just fun daily food challenges!',
      image: Icons.emoji_food_beverage,
    ),
    _OnboardingPageData(
      title: 'Spin for a Challenge',
      description:
          'Spin the wheel to get a quirky food task. Add fun modifiers for extra creativity!',
      image: Icons.casino,
    ),
    _OnboardingPageData(
      title: 'Earn Badges & Track Progress',
      description:
          'Complete daily challenges to earn fun badges and keep your healthy streak going!',
      image: Icons.military_tech,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScaleAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconAnimController.forward();
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconAnimController.forward(from: 0.0);
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    // Save that onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to login screen
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Add Skip button at the top right
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _completeOnboarding(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryCTA,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final isActive = index == _currentPage;
                  return AnimatedBuilder(
                    animation: _iconAnimController,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Transform.translate(
                          offset: Offset(0, isActive ? 0 : 40),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleTransition(
                                  scale: _iconScaleAnim,
                                  child: Icon(
                                    page.image,
                                    size: 100,
                                    color: AppColors.primaryCTA,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  page.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  page.description,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 16,
                  ),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryCTA
                        : AppColors.primaryCTA.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondaryCTA,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 64),
                  if (_currentPage < _pages.length - 1)
                    SizedBox(
                      width: 120,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCTA,
                          foregroundColor: AppColors.textLight,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _completeOnboarding(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCTA,
                            foregroundColor: AppColors.textLight,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData image;
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.image,
  });
}
