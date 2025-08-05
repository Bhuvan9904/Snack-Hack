import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _initLogic();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initLogic() async {
    await Future.delayed(const Duration(seconds: 3));

    // Check if user is logged in with Firebase
    final user = FirebaseAuth.instance.currentUser;
    print('🚀 SPLASH: Firebase Auth user: ${user?.uid ?? 'null'}');

    if (user != null) {
      // User is logged in, go to main app
      print('🚀 SPLASH: User logged in, going to main app');
      if (mounted) {
        context.go('/nav');
      }
    } else {
      // Check if user is in guest mode
      final isGuestValid = await GuestUserService.isGuestSessionValid();
      print('🚀 SPLASH: Guest session valid: $isGuestValid');

      if (isGuestValid) {
        // User is in valid guest mode, go to main app
        print('🚀 SPLASH: Guest user session valid, going to main app');
        if (mounted) {
          context.go('/nav');
        }
      } else {
        // No user logged in and no valid guest session, check if onboarding has been completed
        print('🚀 SPLASH: No user logged in, checking onboarding status...');
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted = prefs.getBool('onboarding_completed');
        print('🚀 SPLASH: Onboarding completed flag: $onboardingCompleted');

        // Only skip onboarding if the flag is explicitly set to true
        if (onboardingCompleted == true) {
          // User has completed onboarding, go to login
          print('🚀 SPLASH: Onboarding completed, going to login');
          if (mounted) {
            context.go('/login');
          }
        } else {
          // First time user or flag not set, show onboarding
          print('🚀 SPLASH: First time user, showing onboarding');
          if (mounted) {
            context.go('/onboarding');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'SnackHack',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryCTA,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppColors.primaryCTA,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
