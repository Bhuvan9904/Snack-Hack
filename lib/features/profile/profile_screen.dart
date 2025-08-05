import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:snack_hack_app/features/profile/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snack_hack_app/providers/app_stats_provider.dart';
import 'package:go_router/go_router.dart';

// Badge model for use in this file
class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String userName = 'You';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    print('👤 PROFILE: Loading user data...');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            userName = userData['name'] ?? 'You';
            isLoading = false;
          });
          print('👤 PROFILE: User data loaded - Name: $userName');
        } else {
          print('❌ PROFILE: User document not found');
          setState(() => isLoading = false);
        }
      } catch (e) {
        print('❌ PROFILE ERROR: $e');
        setState(() => isLoading = false);
      }
    } else {
      print('❌ PROFILE: No user logged in');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(appStatsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.height < 700;

    print(
      'ProfileScreen stats: points=${stats.points}, streak=${stats.streak}, badges=${stats.earnedBadgeIds}',
    );

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryCTA),
        ),
      );
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
              Icons.person,
              color: AppColors.primaryCTA,
              size: isTablet ? 32 : 28,
            ),
            const SizedBox(width: 10),
            Text(
              'PROFILE',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: isTablet ? 26 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 16 : 24),
                Card(
                  color: AppColors.secondary.withOpacity(0.95),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 20 : 24,
                      horizontal: isTablet ? 24 : 18,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              color: AppColors.primaryCTA,
                              size: isTablet ? 36 : 32,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              userName,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: isTablet ? 30 : 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep up the healthy snacking! 🥕',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: AppColors.primaryCTA,
                              size: isTablet ? 30 : 26,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${stats.points}',
                              style: TextStyle(
                                color: AppColors.primaryCTA,
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: isTablet ? 32 : 24),
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: isTablet ? 30 : 26,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${stats.streak}',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 28),
                Card(
                  color: AppColors.secondary.withOpacity(0.95),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 18,
                      horizontal: isTablet ? 16 : 10,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your Badges',
                          style: TextStyle(
                            color: AppColors.primaryCTA,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 20 : 18,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        _buildBadgesRow(stats.earnedBadgeIds),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/badges');
                            },
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.secondaryCTA,
                              size: isTablet ? 22 : 20,
                            ),
                            label: Text(
                              'View All Badges',
                              style: TextStyle(fontSize: isTablet ? 18 : 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryCTA,
                              side: const BorderSide(
                                color: AppColors.secondaryCTA,
                                width: 2,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 32),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 48 : 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _showEditProfileDialog(context);
                    },
                    icon: Icon(Icons.edit, size: isTablet ? 24 : 20),
                    label: Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: isTablet ? 20 : 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCTA,
                      foregroundColor: AppColors.textLight,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 44 : 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.settings,
                      color: AppColors.primaryCTA,
                      size: isTablet ? 22 : 20,
                    ),
                    label: Text(
                      'Settings',
                      style: TextStyle(fontSize: isTablet ? 18 : 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryCTA,
                      side: const BorderSide(
                        color: AppColors.primaryCTA,
                        width: 2,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameController = TextEditingController(text: userName);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: AppColors.textLight),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateUserName(nameController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserName(String newName) async {
    print('👤 PROFILE: Updating user name to: $newName');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});

        setState(() {
          userName = newName;
        });
        print('✅ PROFILE: User name updated successfully!');
      } catch (e) {
        print('❌ PROFILE ERROR: Failed to update user name: $e');
      }
    }
  }

  Widget _buildBadgesRow(List<String> earnedBadgeIds) {
    print('Badges to display: $earnedBadgeIds');
    final allBadges = [
      Badge(
        id: 'first_spin',
        name: 'First Spin',
        description: '',
        icon: Icons.star,
        color: Colors.amber,
      ),
      Badge(
        id: 'healthy_snack',
        name: 'Healthy Snack',
        description: '',
        icon: Icons.emoji_food_beverage,
        color: Colors.green,
      ),
      Badge(
        id: 'streak_3',
        name: 'Streak 3+',
        description: '',
        icon: Icons.bolt,
        color: Colors.orange,
      ),
      Badge(
        id: 'proof_5',
        name: 'Proof Master',
        description: '',
        icon: Icons.camera_alt,
        color: Colors.blue,
      ),
      Badge(
        id: 'challenge_10',
        name: 'Snack Pro',
        description: '',
        icon: Icons.emoji_events,
        color: Colors.purple,
      ),
    ];
    final earnedBadges = allBadges
        .where((b) => earnedBadgeIds.contains(b.id))
        .toList();
    if (earnedBadges.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: AppColors.secondaryCTA.withOpacity(0.7),
          ),
          const SizedBox(height: 10),
          Text(
            'No badges yet.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: earnedBadges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Tooltip(
                message: badge.name,
                child: CircleAvatar(
                  backgroundColor: badge.color.withOpacity(0.15),
                  radius: 24,
                  child: Icon(badge.icon, color: badge.color, size: 28),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
