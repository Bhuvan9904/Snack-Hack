import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/core/services/badge_service.dart';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomChallengeScreen extends StatefulWidget {
  const CustomChallengeScreen({super.key});

  @override
  State<CustomChallengeScreen> createState() => _CustomChallengeScreenState();
}

class _CustomChallengeScreenState extends State<CustomChallengeScreen> {
  final TextEditingController _challengeController = TextEditingController();
  final TextEditingController _customModifierController =
      TextEditingController();

  final Set<String> _selectedModifiers = {};
  final Set<String> _selectedGroupIds = {};
  String _selectedDuration = 'One Day';
  List<Group> _userGroups = [];
  bool _isLoadingGroups = true;
  bool _isCreating = false;

  // Pre-defined modifiers
  final List<Map<String, dynamic>> _availableModifiers = [
    {'id': 'spicy_surge', 'text': 'Spicy Surge', 'icon': '🌶️'},
    {'id': 'healthy_boost', 'text': 'Healthy Boost', 'icon': '🌿'},
    {'id': 'speed_eater', 'text': 'Speed Eater', 'icon': '⏰'},
    {'id': 'mystery_munch', 'text': 'Mystery Munch', 'icon': '⚡'},
  ];

  final List<String> _durationOptions = ['One Day', '3 Days', '1 Week'];

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
      print('❌ CUSTOM CHALLENGE ERROR: Failed to load user groups: $e');
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  void _toggleModifier(String modifierId) {
    setState(() {
      if (_selectedModifiers.contains(modifierId)) {
        _selectedModifiers.remove(modifierId);
      } else if (_selectedModifiers.length < 3) {
        _selectedModifiers.add(modifierId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You can only select up to 3 modifiers'),
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

  Future<void> _launchChallenge() async {
    if (_challengeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write your challenge'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create custom challenge entry
      final entry = ChallengeEntry(
        challengeText: _challengeController.text.trim(),
        date: DateTime.now(),
        modifiers: _selectedModifiers.toList(),
        completed: false,
        category: 'custom',
        difficulty: 'custom',
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await ChallengeService.saveTodaysChallenge(entry);

      // Send to selected groups if any
      if (_selectedGroupIds.isNotEmpty) {
        await _sendChallengeToSelectedGroups(entry);
      }

      // Award badges
      await _awardBadges();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedGroupIds.isEmpty
                  ? 'Custom challenge launched successfully! 🎉'
                  : 'Custom challenge launched and shared with ${_selectedGroupIds.length} group${_selectedGroupIds.length == 1 ? '' : 's'}! 🎉',
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
      print('❌ CUSTOM CHALLENGE ERROR: Failed to launch challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
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

  Future<void> _sendChallengeToSelectedGroups(ChallengeEntry entry) async {
    try {
      print('👥 CUSTOM CHALLENGE: Sending challenge to selected groups...');

      if (_selectedGroupIds.isEmpty) {
        print(
          '👥 CUSTOM CHALLENGE: No groups selected, skipping group assignment',
        );
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
          description:
              'Custom challenge with ${_selectedModifiers.length} modifiers',
          imageUrl: '',
          modifiers: _selectedModifiers.toList(),
          submittedAt: DateTime.now(),
          votes: {},
        );

        await GroupService.submitToGroup(submission);
        print('👥 CUSTOM CHALLENGE: Challenge sent to group: ${group.name}');
      }

      print(
        '✅ CUSTOM CHALLENGE: Challenge sent to ${_selectedGroupIds.length} selected groups',
      );
    } catch (e) {
      print('❌ CUSTOM CHALLENGE ERROR: Failed to send challenge to groups: $e');
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
      print('❌ CUSTOM CHALLENGE ERROR: Failed to award badges: $e');
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
        title: const Text(
          'Create Custom Challenge',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Write Your Challenge
                  _buildSection(
                    number: 1,
                    title: 'Write Your Challenge',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Write a short food challenge.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Example: Eat something that starts with the letter B.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _challengeController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter your custom challenge...',
                            hintStyle: TextStyle(
                              color: AppColors.textLight.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: AppColors.secondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section 2: Add Modifiers
                  _buildSection(
                    number: 2,
                    title: 'Add Modifiers',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select up to 3 pre-existing modifiers:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableModifiers.map((modifier) {
                            final isSelected = _selectedModifiers.contains(
                              modifier['id'],
                            );
                            return GestureDetector(
                              onTap: () => _toggleModifier(modifier['id']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryCTA
                                      : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryCTA
                                        : AppColors.primary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      modifier['icon'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      modifier['text'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Or add a custom modifier (optional):',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _customModifierController,
                          decoration: InputDecoration(
                            hintText:
                                "Enter custom modifier (e.g., 'Vegan Twist')",
                            hintStyle: TextStyle(
                              color: AppColors.textLight.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: AppColors.secondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section 3: Group Targeting
                  _buildSection(
                    number: 3,
                    title: 'Group Targeting',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select groups to share your challenge with:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.8),
                          ),
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
                                        ? AppColors.secondaryCTA.withOpacity(
                                            0.2,
                                          )
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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

                  const SizedBox(height: 32),

                  // Section 4: Challenge Duration
                  _buildSection(
                    number: 4,
                    title: 'Challenge Duration',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: _durationOptions.map((duration) {
                            final isSelected = _selectedDuration == duration;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDuration = duration;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryCTA
                                        : AppColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryCTA
                                          : AppColors.primary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    duration,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start Today',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Launch Challenge Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _launchChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCTA,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Launch Challenge'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required int number,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryCTA,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
