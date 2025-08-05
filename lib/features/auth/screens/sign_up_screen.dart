import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/features/auth/widgets/custome_widget.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _loading = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }

    final password = value.trim();
    final errors = <String>[];

    // Check length
    if (password.length < 6) {
      errors.add('at least 6 characters');
    }

    // Check for letters
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      errors.add('at least 1 letter');
    }

    // Check for numbers
    if (!RegExp(r'\d').hasMatch(password)) {
      errors.add('at least 1 number');
    }

    if (errors.isNotEmpty) {
      return 'Password must contain: ${errors.join(', ')}';
    }

    return null;
  }

  Future<void> _signupUser() async {
    print('📝 SIGNUP: Starting signup process...');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('📝 SIGNUP: Creating Firebase Auth user...');
      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      print(
        '📝 SIGNUP: Firebase Auth user created! User ID: ${userCredential.user?.uid}',
      );

      if (userCredential.user != null) {
        print('📝 SIGNUP: Saving user data to Firestore...');
        // Save user data to Firestore
        final userData = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'streak': 0,
          'earnedBadges': [],
          'settings': {'vegetarian': false, 'darkMode': false},
        };

        print('📝 SIGNUP: User data to save:');
        print('   - Name: ${userData['name']}');
        print('   - Email: ${userData['email']}');
        print('   - Points: ${userData['points']}');
        print('   - Streak: ${userData['streak']}');
        print('   - Badges: ${userData['earnedBadges']}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        print('📝 SIGNUP: User data saved to Firestore successfully!');

        // Transfer guest spin count if any
        await _transferGuestSpinCount(userCredential.user!.uid);

        // End any existing guest session
        await GuestUserService.endGuestSession();

        if (!mounted) return;
        print('📝 SIGNUP: Navigating to main app...');
        context.go('/nav');
      }
    } catch (e) {
      print('❌ SIGNUP ERROR: $e');
      setState(() {
        _error = _getUserFriendlySignupErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithApple() async {
    print('🍎 APPLE SIGNUP: Starting Apple Sign-Up...');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        print('❌ APPLE SIGNUP: Apple Sign-In not available');
        setState(() {
          _error = 'Apple Sign-In is not available on this device.';
          _loading = false;
        });
        return;
      }

      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('🍎 APPLE SIGNUP: Apple credential received');
      print('   - User ID: ${credential.userIdentifier}');
      print('   - Email: ${credential.email}');
      print('   - Name: ${credential.givenName} ${credential.familyName}');

      // Create Firebase credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user != null) {
        // Save user data to Firestore
        final userData = {
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim(),
          'email': credential.email ?? '',
          'appleUserId': credential.userIdentifier,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'streak': 0,
          'earnedBadges': [],
          'settings': {'vegetarian': false},
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        print('🍎 APPLE SIGNUP: User data saved to Firestore successfully!');

        // End any existing guest session
        await GuestUserService.endGuestSession();

        if (!mounted) return;
        print('🍎 APPLE SIGNUP: Navigating to main app...');
        context.go('/nav');
      }
    } catch (e) {
      print('❌ APPLE SIGNUP ERROR: $e');
      setState(() {
        _error = 'Apple Sign-Up failed. Please try again or use email signup.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transferGuestSpinCount(String userId) async {
    try {
      print('🔄 SIGNUP: Checking for guest spin count to transfer...');
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getDateKey(DateTime.now());
      final guestSpins = prefs.getInt('spins_$todayKey') ?? 0;

      if (guestSpins > 0) {
        print(
          '🔄 SIGNUP: Found guest spins: $guestSpins, transferring to Firestore...',
        );

        // Get current Firestore spins
        final firestoreDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('spins')
            .doc(todayKey)
            .get();

        int firestoreSpins = firestoreDoc.data()?['count'] ?? 0;
        print('🔄 SIGNUP: Current Firestore spins: $firestoreSpins');

        // Use the higher count (don't lose spins)
        final finalSpins = guestSpins > firestoreSpins
            ? guestSpins
            : firestoreSpins;

        // Update Firestore with the higher count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('spins')
            .doc(todayKey)
            .set({'count': finalSpins});

        // Clear guest spins from SharedPreferences
        await prefs.remove('spins_$todayKey');
        await prefs.remove('last_spin_date');

        print(
          '🔄 SIGNUP: Spin count transferred successfully. Final count: $finalSpins',
        );
      } else {
        print('🔄 SIGNUP: No guest spins to transfer');
      }
    } catch (e) {
      print('❌ SIGNUP ERROR: Failed to transfer guest spin count: $e');
    }
  }

  String _getDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Convert Firebase signup errors to user-friendly messages
  String _getUserFriendlySignupErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists. Please try logging in instead.';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (errorString.contains('operation-not-allowed')) {
      return 'Email/password signup is not enabled. Please contact support.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Signup failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'SIGN UP',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Icon(
                    Icons.person_add,
                    size: 64,
                    color: AppColors.primaryCTA,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join SnackHack and start your healthy snack adventure!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(controller: nameController, label: 'Full Name'),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Enter a valid email (e.g., example@gmail.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: _validatePassword,
                  helperText:
                      'Must contain at least 6 characters, 1 letter, and 1 number',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryCTA,
                        ),
                      )
                    : SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _signupUser();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCTA,
                            foregroundColor: AppColors.textLight,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryCTA,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Already have an account? Login'),
                ),
                const SizedBox(height: 24),
                // Divider with "or" text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.textLight.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.textLight.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Apple Sign-In Button
                SizedBox(
                  height: 48,
                  child: SignInWithAppleButton(
                    onPressed: _loading ? () {} : () => _signUpWithApple(),
                    style: SignInWithAppleButtonStyle.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      // For guest mode, we'll still use local storage for now
                      // TODO: Implement guest mode with Firebase
                      context.go('/nav');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryCTA,
                      side: BorderSide(color: AppColors.secondaryCTA),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
