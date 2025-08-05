import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';

// Global flag to track if account deletion is pending
bool accountDeletionPending = false;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vegetarian = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    print('⚙️ SETTINGS: Loading user settings...');
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Firebase authenticated user
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final settings = userData['settings'] ?? {};
          setState(() {
            _vegetarian = settings['vegetarian'] ?? false;
            _loading = false;
          });
          print('⚙️ SETTINGS: Settings loaded - Vegetarian: $_vegetarian');
        } else {
          print('❌ SETTINGS: User document not found');
          setState(() => _loading = false);
        }
      } catch (e) {
        print('❌ SETTINGS ERROR: $e');
        setState(() => _loading = false);
      }
    } else {
      // Guest user - load from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final isGuestValid = await GuestUserService.isGuestSessionValid();
        
        if (isGuestValid) {
          final vegetarian = prefs.getBool('guest_vegetarian') ?? false;
          setState(() {
            _vegetarian = vegetarian;
            _loading = false;
          });
          print('⚙️ SETTINGS: Guest settings loaded - Vegetarian: $_vegetarian');
        } else {
          print('❌ SETTINGS: Guest session not valid');
          setState(() => _loading = false);
        }
      } catch (e) {
        print('❌ SETTINGS ERROR: Failed to load guest settings: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    print('⚙️ SETTINGS: Saving settings...');
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Firebase authenticated user
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'settings': {'vegetarian': _vegetarian},
            });
        print('✅ SETTINGS: Settings saved successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      } catch (e) {
        print('❌ SETTINGS ERROR: Failed to save settings: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    } else {
      // Guest user - save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('guest_vegetarian', _vegetarian);
        print('✅ SETTINGS: Guest settings saved successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      } catch (e) {
        print('❌ SETTINGS ERROR: Failed to save guest settings: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isIPhone = screenSize.width < 400;
    final isSmallScreen = screenSize.height < 700;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings, 
              color: AppColors.primaryCTA, 
              size: isTablet ? 30 : (isIPhone ? 22 : 26)
            ),
            SizedBox(width: isIPhone ? 8 : 10),
            Text(
              'SETTINGS',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: isTablet ? 24 : (isIPhone ? 16 : 20),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : (isIPhone ? 16 : 24)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Settings Section
                Card(
                  color: AppColors.secondary,
                  elevation: 4,
                  shadowColor: AppColors.primaryCTA.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : (isIPhone ? 16 : 20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          children: [
                            Icon(
                              Icons.tune, 
                              color: AppColors.primaryCTA,
                              size: isTablet ? 28 : (isIPhone ? 20 : 24)
                            ),
                            SizedBox(width: isIPhone ? 8 : 12),
                            Text(
                              'Preferences',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: isTablet ? 22 : (isIPhone ? 16 : 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isIPhone ? 16 : 20),
                        
                        // Vegetarian Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            border: Border.all(
                              color: AppColors.primaryCTA.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: SwitchListTile(
                            value: _vegetarian,
                            onChanged: (val) => setState(() => _vegetarian = val),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.eco, 
                                  color: AppColors.primaryCTA,
                                  size: isTablet ? 24 : (isIPhone ? 18 : 20)
                                ),
                                SizedBox(width: isIPhone ? 8 : 12),
                                Expanded(
                                  child: Text(
                                    'Vegetarian',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: isTablet ? 18 : (isIPhone ? 14 : 16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(
                                left: isIPhone ? 26 : 32,
                                top: isIPhone ? 4 : 6
                              ),
                              child: Text(
                                'Get vegetarian-friendly challenge suggestions',
                                style: TextStyle(
                                  color: AppColors.textLight.withOpacity(0.7),
                                  fontSize: isTablet ? 14 : (isIPhone ? 11 : 13),
                                ),
                              ),
                            ),
                            activeColor: AppColors.primaryCTA,
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[700],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 20 : (isIPhone ? 12 : 16),
                              vertical: isIPhone ? 8 : 12
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isIPhone ? 20 : 28),
                
                // Save Settings Button
                SizedBox(
                  width: double.infinity,
                  height: isTablet ? 60 : (isIPhone ? 48 : 52),
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: Icon(
                      Icons.save,
                      size: isTablet ? 26 : (isIPhone ? 20 : 24),
                    ),
                    label: Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : (isIPhone ? 16 : 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCTA,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                
                SizedBox(height: isIPhone ? 16 : 24),
                
                // Account Actions Section
                Card(
                  color: AppColors.secondary,
                  elevation: 4,
                  shadowColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : (isIPhone ? 16 : 20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle, 
                              color: Colors.redAccent,
                              size: isTablet ? 28 : (isIPhone ? 20 : 24)
                            ),
                            SizedBox(width: isIPhone ? 8 : 12),
                            Text(
                              'Account Actions',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: isTablet ? 22 : (isIPhone ? 16 : 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isIPhone ? 16 : 20),
                        
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 56 : (isIPhone ? 44 : 48),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.logout, 
                              size: isTablet ? 24 : (isIPhone ? 18 : 20)
                            ),
                            label: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : (isIPhone ? 14 : 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.redAccent,
                                        size: isTablet ? 28 : (isIPhone ? 20 : 24)
                                      ),
                                      SizedBox(width: isIPhone ? 8 : 12),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: isTablet ? 22 : (isIPhone ? 18 : 20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppColors.primaryCTA,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                                        ),
                                      ),
                                      child: Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                print('🚪 LOGOUT: Signing out user...');
                                final user = FirebaseAuth.instance.currentUser;
                                
                                if (user != null) {
                                  // Firebase authenticated user
                                  await FirebaseAuth.instance.signOut();
                                  print('🚪 LOGOUT: Firebase user signed out successfully');
                                } else {
                                  // Guest user - clear guest data
                                  await GuestUserService.endGuestSession();
                                  print('🚪 LOGOUT: Guest user data cleared successfully');
                                }
                                
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              }
                            },
                          ),
                        ),
                        
                        SizedBox(height: isIPhone ? 12 : 16),
                        
                        // Delete Account Button
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 56 : (isIPhone ? 44 : 48),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.delete_forever,
                              size: isTablet ? 24 : (isIPhone ? 18 : 20)
                            ),
                            label: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : (isIPhone ? 14 : 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                        size: isTablet ? 28 : (isIPhone ? 20 : 24)
                                      ),
                                      SizedBox(width: isIPhone ? 8 : 12),
                                      Text(
                                        'Delete Account',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: isTablet ? 22 : (isIPhone ? 18 : 20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    FirebaseAuth.instance.currentUser != null
                                        ? 'This will permanently delete your account and all data. This action cannot be undone.'
                                        : 'This will permanently clear all your guest data and reset the app. This action cannot be undone.',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppColors.primaryCTA,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                                        ),
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 16 : (isIPhone ? 14 : 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                print('🗑️ DELETE: Deleting user account...');
                                final user = FirebaseAuth.instance.currentUser;
                                
                                if (user != null) {
                                  // Firebase authenticated user
                                  try {
                                    // Delete all user data from Firestore
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .delete();

                                    // Delete all subcollections
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('challenges')
                                        .get()
                                        .then((snapshot) {
                                          for (var doc in snapshot.docs) {
                                            doc.reference.delete();
                                          }
                                        });

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('submissions')
                                        .get()
                                        .then((snapshot) {
                                          for (var doc in snapshot.docs) {
                                            doc.reference.delete();
                                          }
                                        });

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('spins')
                                        .get()
                                        .then((snapshot) {
                                          for (var doc in snapshot.docs) {
                                            doc.reference.delete();
                                          }
                                        });

                                    // Delete the user account
                                    await user.delete();
                                    print('🗑️ DELETE: Firebase account deleted successfully');

                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  } catch (e) {
                                    print('❌ DELETE ERROR: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete account: $e'),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  // Guest user - clear all guest data
                                  try {
                                    await GuestUserService.endGuestSession();
                                    
                                    // Clear all guest-related data from SharedPreferences
                                    final prefs = await SharedPreferences.getInstance();
                                    final keys = prefs.getKeys();
                                    
                                    for (final key in keys) {
                                      if (key.startsWith('guest_')) {
                                        await prefs.remove(key);
                                      }
                                    }
                                    
                                    print('🗑️ DELETE: Guest account data cleared successfully');
                                    
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  } catch (e) {
                                    print('❌ DELETE ERROR: Failed to clear guest data: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete account: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom spacing for safe area
                SizedBox(height: isIPhone ? 20 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
