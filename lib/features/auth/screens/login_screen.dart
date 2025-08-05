// For hashing
// For hashing, add to pubspec.yaml
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/features/auth/widgets/custome_widget.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:snack_hack_app/features/profile/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _loading = false; // ADDED

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _loginUser() async {
    print('🔐 LOGIN: Starting login process...');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🔐 LOGIN: Attempting Firebase Auth sign in...');
      // Use Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      print(
        '🔐 LOGIN: Firebase Auth successful! User ID: ${userCredential.user?.uid}',
      );

      if (userCredential.user != null) {
        // End any existing guest session
        await GuestUserService.endGuestSession();
        // Check if account deletion is pending
        if (accountDeletionPending) {
          print('🔄 LOGIN: Account deletion pending, completing deletion...');
          try {
            // Delete the user account now that they're re-authenticated
            await userCredential.user!.delete();
            print('🔄 LOGIN: Account deletion completed successfully');

            // Reset the flag
            accountDeletionPending = false;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deleted successfully. You can now create a new account.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return; // Don't proceed to main app
          } catch (e) {
            print('❌ LOGIN: Failed to complete account deletion: $e');
            // Reset the flag even if deletion fails
            accountDeletionPending = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to complete account deletion. Please try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        print('🔐 LOGIN: Fetching user data from Firestore...');
        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          print('🔐 LOGIN: User data found in Firestore:');
          print('   - Name: ${userData['name']}');
          print('   - Email: ${userData['email']}');
          print('   - Points: ${userData['points']}');
          print('   - Streak: ${userData['streak']}');
          print('   - Badges: ${userData['earnedBadges']}');

          // Transfer guest spin count if any
          await _transferGuestSpinCount(userCredential.user!.uid);

          if (!mounted) return;
          print('🔐 LOGIN: Navigating to main app...');
          context.go('/nav');
        } else {
          print('❌ LOGIN: User document not found in Firestore!');
          setState(
            () => _error = 'Account not found. Please check your credentials.',
          );
        }
      } else {
        print('❌ LOGIN: Firebase Auth returned null user!');
        setState(() => _error = 'Login failed. Please try again.');
      }
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      setState(() => _error = _getUserFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    print('🍎 APPLE LOGIN: Starting Apple Sign-In...');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        print('❌ APPLE LOGIN: Apple Sign-In not available');
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

      print('🍎 APPLE LOGIN: Apple credential received');
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
        // Check if account deletion is pending
        if (accountDeletionPending) {
          print(
            '🔄 APPLE LOGIN: Account deletion pending, completing deletion...',
          );
          try {
            // Delete the user account now that they're re-authenticated
            await userCredential.user!.delete();
            print('🔄 APPLE LOGIN: Account deletion completed successfully');

            // Reset the flag
            accountDeletionPending = false;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deleted successfully. You can now create a new account.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return; // Don't proceed to main app
          } catch (e) {
            print('❌ APPLE LOGIN: Failed to complete account deletion: $e');
            // Reset the flag even if deletion fails
            accountDeletionPending = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to complete account deletion. Please try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create new user document
          final userData = {
            'name':
                '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
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

          print('🍎 APPLE LOGIN: New user created in Firestore');
        } else {
          print('🍎 APPLE LOGIN: Existing user found in Firestore');
        }

        // Transfer guest spin count if any
        await _transferGuestSpinCount(userCredential.user!.uid);

        // End any existing guest session
        await GuestUserService.endGuestSession();

        if (!mounted) return;
        print('🍎 APPLE LOGIN: Navigating to main app...');
        context.go('/nav');
      }
    } catch (e) {
      print('❌ APPLE LOGIN ERROR: $e');
      setState(() => _error = 'Apple Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transferGuestSpinCount(String userId) async {
    try {
      print('🔄 LOGIN: Checking for guest spin count to transfer...');
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getDateKey(DateTime.now());
      final guestSpins = prefs.getInt('spins_$todayKey') ?? 0;

      if (guestSpins > 0) {
        print(
          '🔄 LOGIN: Found guest spins: $guestSpins, transferring to Firestore...',
        );

        // Get current Firestore spins
        final firestoreDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('spins')
            .doc(todayKey)
            .get();

        int firestoreSpins = firestoreDoc.data()?['count'] ?? 0;
        print('🔄 LOGIN: Current Firestore spins: $firestoreSpins');

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
          '🔄 LOGIN: Spin count transferred successfully. Final count: $finalSpins',
        );
      } else {
        print('🔄 LOGIN: No guest spins to transfer');
      }
    } catch (e) {
      print('❌ LOGIN ERROR: Failed to transfer guest spin count: $e');
    }
  }

  String _getDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Convert Firebase errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please check your email or sign up.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Login failed. Please check your credentials and try again.';
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
            Icon(Icons.login, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'LOGIN',
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
                // Playful icon header
                Center(
                  child: Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: AppColors.primaryCTA,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue your healthy snack adventure.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
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
                              _loginUser();
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
                          child: const Text('Login'),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryCTA,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text("Don't have an account? Sign up"),
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
                    onPressed: _loading ? () {} : () => _signInWithApple(),
                    style: SignInWithAppleButtonStyle.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Start guest session and go to main app
                      await GuestUserService.startGuestSession();
                      print(
                        '👤 LOGIN: Guest session started, navigating to main app',
                      );
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
