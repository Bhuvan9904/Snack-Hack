import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/core/services/badge_service.dart';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snack_hack_app/features/spin/custom_challenge_screen.dart';

class ModifierSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final Map<String, dynamic> category;

  const ModifierSelectionScreen({
    super.key,
    required this.challenge,
    required this.category,
  });

  @override
  State<ModifierSelectionScreen> createState() =>
      _ModifierSelectionScreenState();
}

class _ModifierSelectionScreenState extends State<ModifierSelectionScreen> {
  final Set<String> _selectedModifiers = {};
  final Set<String> _selectedGroupIds = {};
  static const int maxModifiers = 3;
  List<Group> _userGroups = [];
  bool _isLoadingGroups = true;

  // Pre-defined modifiers with icons
  final List<Map<String, dynamic>> _availableModifiers = [
    {'id': 'chopsticks', 'text': 'Use chopsticks', 'icon': '🥢', 'points': 2},
    {
      'id': 'blindfolded',
      'text': 'Eat blindfolded',
      'icon': '👁️',
      'points': 3,
    },
    {
      'id': 'three_ingredients',
      'text': 'Only 3 ingredients',
      'icon': '🥕',
      'points': 2,
    },
    {'id': 'outdoors', 'text': 'Snack outdoors', 'icon': '🧺', 'points': 2},
    {'id': 'fancy', 'text': 'Make it fancy', 'icon': '👨‍🍳', 'points': 2},
    {'id': 'spicy', 'text': 'Spicy challenge', 'icon': '🌶️', 'points': 3},
    {'id': 'sweet_ending', 'text': 'Sweet ending', 'icon': '🍦', 'points': 1},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    try {
      final groups = await GroupService.getUserGroups();
      setState(() {
        _userGroups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      print('❌ MODIFIER ERROR: Failed to load user groups: $e');
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  void _toggleModifier(String modifierId) {
    setState(() {
      if (_selectedModifiers.contains(modifierId)) {
        _selectedModifiers.remove(modifierId);
      } else if (_selectedModifiers.length < maxModifiers) {
        _selectedModifiers.add(modifierId);
      } else {
        // Show snackbar if trying to select more than max
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only select up to $maxModifiers modifiers'),
            backgroundColor: AppColors.primaryCTA,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  Future<void> _startChallenge() async {
    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select at least one group to share your challenge with',
          ),
          backgroundColor: AppColors.primaryCTA,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      // Create challenge entry
      final entry = ChallengeEntry(
        challengeText: widget.challenge['text'],
        date: DateTime.now(),
        modifiers: _selectedModifiers.toList(),
        completed: false,
        category: widget.category['id'],
        difficulty: 'easy',
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await ChallengeService.saveTodaysChallenge(entry);

      // Send challenge to selected groups only
      await _sendChallengeToSelectedGroups(entry);

      // Award badges
      await _awardBadges();

      // Navigate back to home
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Challenge started and shared with ${_selectedGroupIds.length} group${_selectedGroupIds.length == 1 ? '' : 's'}! 🎉',
            ),
            backgroundColor: AppColors.primaryCTA,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ MODIFIER ERROR: Failed to start challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendChallengeToSelectedGroups(ChallengeEntry entry) async {
    try {
      print('👥 MODIFIER: Sending challenge to selected groups...');

      if (_selectedGroupIds.isEmpty) {
        print('👥 MODIFIER: No groups selected, skipping group assignment');
        return;
      }

      for (final groupId in _selectedGroupIds) {
        final group = _userGroups.firstWhere((g) => g.id == groupId);
        final submission = GroupSubmission(
          id: '${entry.id}_${groupId}',
          groupId: groupId,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          challengeId: entry.id,
          title: entry.challengeText,
          description: 'Challenge with ${_selectedModifiers.length} modifiers',
          imageUrl: '',
          modifiers: _selectedModifiers.toList(),
          submittedAt: DateTime.now(),
          votes: {},
        );

        await GroupService.submitToGroup(submission);
        print('👥 MODIFIER: Challenge sent to group: ${group.name}');
      }

      print(
        '✅ MODIFIER: Challenge sent to ${_selectedGroupIds.length} selected groups',
      );
    } catch (e) {
      print('❌ MODIFIER ERROR: Failed to send challenge to groups: $e');
    }
  }

  Future<void> _awardBadges() async {
    try {
      final spinsToday = await ChallengeService.getSpinsToday();
      final streak = await ChallengeService.getStreak();
      final points = await ChallengeService.getPoints();
      final submissions = await ChallengeSubmissionService.getAllSubmissions();
      final proofCount = submissions.length;
      final healthySnackSubmitted = submissions.any(
        (s) => s.tags.contains('healthy'),
      );
      final challenges = await ChallengeService.getUserChallenges();
      final completedChallenges = challenges
          .where((challenge) => challenge.completed)
          .length;

      await BadgeService.checkAndAwardBadges(
        totalSpins: spinsToday,
        streak: streak,
        proofCount: proofCount,
        completedChallenges: completedChallenges,
        healthySnackSubmitted: healthySnackSubmitted,
        modifierPoints:
            _selectedModifiers.length * 2, // Simple point calculation
        modifiersUsed: _selectedModifiers.length,
        modifierIds: _selectedModifiers.toList(),
      );
    } catch (e) {
      print('❌ MODIFIER ERROR: Failed to award badges: $e');
    }
  }

  void _navigateToCustomChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomChallengeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Modifiers',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24),
            onPressed: () {},
          ),
          // Padding(
          //   padding: const EdgeInsets.only(right: 16.0),
          //   child: CircleAvatar(
          //     backgroundColor: AppColors.secondaryCTA,
          //     radius: 16,
          //     child: const Text(
          //       'JD', // This is a placeholder - should be user's initials
          //       style: TextStyle(
          //         color: AppColors.textDark,
          //         fontWeight: FontWeight.bold,
          //         fontSize: 14,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.2, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Challenge Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryCTA.withOpacity(0.8),
                        AppColors.primaryCTA,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCTA.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  widget.category['emoji'] ?? '🍜',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.category['name'] ?? 'Challenge',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Category Challenge',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.challenge['text'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                // Modifier Selection Section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCTA.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primaryCTA,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose Your Modifiers',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  'Select up to $maxModifiers modifiers to spice up your challenge!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textLight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Responsive Modifier Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 600
                              ? 3
                              : 2;
                          final childAspectRatio = constraints.maxWidth > 600
                              ? 1.8
                              : 1.4;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _availableModifiers.length,
                            itemBuilder: (context, index) {
                              final modifier = _availableModifiers[index];
                              final isSelected = _selectedModifiers.contains(
                                modifier['id'],
                              );

                              return GestureDetector(
                                onTap: () => _toggleModifier(modifier['id']),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryCTA
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryCTA
                                              : AppColors.primary.withOpacity(
                                                  0.3,
                                                ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? AppColors.primaryCTA
                                                      .withOpacity(0.3)
                                                : Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withOpacity(
                                                        0.2,
                                                      )
                                                    : AppColors.primary
                                                          .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                modifier['icon'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Flexible(
                                              child: Text(
                                                modifier['text'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors.textLight,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '+${modifier['points']} pts',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : AppColors.textLight
                                                          .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: AppColors.primaryCTA,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20.0 : 24.0),

                // Group Selection Section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCTA.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.groups,
                              color: AppColors.secondaryCTA,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Groups to Share',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  'Choose which groups will see your challenge',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textLight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_isLoadingGroups)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryCTA,
                            ),
                          ),
                        )
                      else if (_userGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.group_off,
                                size: 40,
                                color: AppColors.textLight.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No groups available',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create or join a group first',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _userGroups.map((group) {
                            final isSelected = _selectedGroupIds.contains(
                              group.id,
                            );
                            return GestureDetector(
                              onTap: () => _toggleGroup(group.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondaryCTA.withOpacity(0.2)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secondaryCTA
                                        : AppColors.primary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.secondaryCTA
                                            : AppColors.primary.withOpacity(
                                                0.3,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        group.name.isNotEmpty
                                            ? group.name[0].toUpperCase()
                                            : 'G',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.secondaryCTA
                                                  : AppColors.textLight,
                                            ),
                                          ),
                                          Text(
                                            '${group.members.length} members',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? AppColors.secondaryCTA
                                                        .withOpacity(0.8)
                                                  : AppColors.textLight
                                                        .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryCTA,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20.0 : 24.0),

                // Selected Modifiers Summary
                if (_selectedModifiers.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCTA.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryCTA.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryCTA,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Selected Modifiers (${_selectedModifiers.length}/$maxModifiers)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedModifiers.map((modifierId) {
                            final modifier = _availableModifiers.firstWhere(
                              (m) => m['id'] == modifierId,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCTA,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryCTA.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    modifier['icon'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      modifier['text'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24.0 : 32.0),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _navigateToCustomChallenge,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.secondaryCTA,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CREATE CUSTOM',
                          style: TextStyle(
                            color: AppColors.secondaryCTA,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedModifiers.isNotEmpty
                            ? _startChallenge
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCTA,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: AppColors.primaryCTA.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Start Challenge',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
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
