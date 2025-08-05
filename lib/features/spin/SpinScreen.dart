import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/modifier_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:snack_hack_app/features/spin/modifier_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => SpinScreenState();
}

class SpinScreenState extends State<SpinScreen> with WidgetsBindingObserver {
  StreamController<int>? _selected;
  int? _lastSelectedIndex;
  bool _isSpinning = false;
  bool _isLoadingChallenges = false;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedChallenge;
  List<Map<String, dynamic>> _categoryChallenges = [];
  String? _selectedChallengeId;

  // New categories with emojis
  final List<Map<String, dynamic>> _categories = [
    {
      "id": "colorful_plates",
      "name": "Colorful Plates",
      "emoji": "🌈",
      "description": "Represents vibrant, multi-colored meals",
    },
    {
      "id": "quick_fix_snacks",
      "name": "Quick Fix Snacks",
      "emoji": "⏱️",
      "description": "Speedy, time-friendly snacks",
    },
    {
      "id": "no_sugar_moments",
      "name": "No Sugar Moments",
      "emoji": "🚫🍬",
      "description": "No-sugar or reduced-sugar focus",
    },
    {
      "id": "creative_combos",
      "name": "Creative Combos",
      "emoji": "🧪",
      "description": "Fun food experiments and flavor fusions",
    },
    {
      "id": "mindful_eating",
      "name": "Mindful Eating",
      "emoji": "🧘‍♀️",
      "description": "Reflective, calm, screen-free eating",
    },
    {
      "id": "ingredient_spotlight",
      "name": "Ingredient Spotlight",
      "emoji": "🥄",
      "description": "Focused on one star ingredient",
    },
    {
      "id": "other_miscellaneous",
      "name": "Other / Miscellaneous",
      "emoji": "🎲",
      "description": "Random or mixed challenges not in the above 6",
    },
  ];

  final List<Color> _segmentColors = [
    Color(0xFF8F00FF), // Violet
    Color(0xFF4B0082), // Indigo
    Color(0xFF0000FF), // Blue
    Color(0xFF00FF00), // Green
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF7F00), // Orange
    Color(0xFFFF0000), // Red
  ];

  static const int maxSpinsPerDay = 10;
  int _spinsToday = 0;
  bool _challengeAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStreamController();
    _loadSpinState();
  }

  void _initializeStreamController() {
    _selected?.close();
    _selected = StreamController<int>.broadcast();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selected?.close();
    _selected = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh state when app comes back to foreground
      print('🔄 SPIN: App resumed, refreshing state...');
      _loadSpinState();
      // Ensure stream controller is properly initialized after app resume
      if (_selected == null || _selected!.isClosed) {
        _initializeStreamController();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is going to background, save current state
      print('🔄 SPIN: App paused, saving state...');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure stream controller is initialized when dependencies change
    if (_selected == null || _selected!.isClosed) {
      _initializeStreamController();
    }
  }

  Future<void> _loadSpinState() async {
    try {
      print('🔄 SPIN: Loading spin state...');

      // Ensure stream controller is initialized
      if (_selected == null || _selected!.isClosed) {
        _initializeStreamController();
      }

      // Auto-approve old pending submissions first
      await _autoApproveOldSubmissions();

      await ChallengeService.resetSpinsIfNewDay();
      final spins = await ChallengeService.getSpinsToday();
      final challenge = await ChallengeService.getTodaysChallenge();

      print('🔄 SPIN: Loaded spins today: $spins');
      print('🔄 SPIN: Challenge accepted: ${challenge != null}');
      print(
        '🔄 SPIN: Challenge details: ${challenge?.challengeText ?? 'null'}',
      );
      print('🔄 SPIN: Challenge completed: ${challenge?.completed ?? 'null'}');

      // Check if this is a fresh login after reset
      // If user has no spins and no challenge, ensure clean state
      if (spins == 0 && challenge == null) {
        print('🔄 SPIN: Fresh login detected, ensuring clean state...');
        // Force clear any residual challenge data
        await ChallengeService.clearTodaysChallenge();
      }

      // Additional safety check: if challenge exists but user has no spins,
      // this might be residual data from before reset
      if (spins == 0 && challenge != null) {
        print('🔄 SPIN: Detected residual challenge data, clearing...');
        await ChallengeService.clearTodaysChallenge();
        // Reload the state after clearing
        final updatedChallenge = await ChallengeService.getTodaysChallenge();
        setState(() {
          _spinsToday = spins;
          _challengeAccepted = updatedChallenge != null;
          if (updatedChallenge == null) {
            _selectedCategory = null;
            _selectedChallenge = null;
            _categoryChallenges = [];
            _selectedChallengeId = null;
            _lastSelectedIndex = null;
          }
        });
        return;
      }

      setState(() {
        _spinsToday = spins;
        _challengeAccepted = challenge != null;
        // Reset other states when no challenge is present
        if (challenge == null) {
          _selectedCategory = null;
          _selectedChallenge = null;
          _categoryChallenges = [];
          _selectedChallengeId = null;
          _lastSelectedIndex = null;
        }
      });

      print(
        '🔄 SPIN: Spin state updated in UI - _challengeAccepted: $_challengeAccepted',
      );
    } catch (e) {
      print('❌ SPIN ERROR: Failed to load spin state: $e');
    }
  }

  Future<void> refresh() async {
    // Ensure stream controller is properly initialized before refresh
    if (_selected == null || _selected!.isClosed) {
      _initializeStreamController();
    }
    await _loadSpinState();
  }

  Future<void> resetSpinScreen() async {
    try {
      print('🔄 SPIN: Resetting spin screen state...');

      // Clear today's challenge
      await ChallengeService.clearTodaysChallenge();

      // Reset stream controller
      _initializeStreamController();

      // Reset all local state
      setState(() {
        _challengeAccepted = false;
        _selectedCategory = null;
        _selectedChallenge = null;
        _categoryChallenges = [];
        _selectedChallengeId = null;
        _lastSelectedIndex = null;
        _isSpinning = false;
      });

      // Reload spin state to get updated spin count
      await _loadSpinState();

      print('✅ SPIN: Spin screen reset successfully');
    } catch (e) {
      print('❌ SPIN ERROR: Failed to reset spin screen: $e');
    }
  }

  Future<void> _sendChallengeToGroups(ChallengeEntry entry) async {
    try {
      print('👥 SPIN: Sending challenge to user groups...');

      // Get user's groups
      final groups = await GroupService.getUserGroups();

      if (groups.isEmpty) {
        print('👥 SPIN: User has no groups, skipping group assignment');
        return;
      }

      // Create a group submission for each group
      for (final group in groups) {
        final submission = GroupSubmission(
          id: '${entry.id}_${group.id}',
          groupId: group.id,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          challengeId: entry.id,
          title: entry.challengeText,
          description: 'Challenge accepted from spin wheel',
          imageUrl: '', // Will be updated when user submits photo
          modifiers: [],
          submittedAt: DateTime.now(),
          votes: {},
        );

        await GroupService.submitToGroup(submission);
        print('👥 SPIN: Challenge sent to group: ${group.name}');
      }

      print('✅ SPIN: Challenge sent to ${groups.length} groups');
    } catch (e) {
      print('❌ SPIN ERROR: Failed to send challenge to groups: $e');
    }
  }

  void _spinWheel() async {
    if (_isSpinning || _spinsToday >= maxSpinsPerDay || _challengeAccepted) {
      return;
    }

    print('🎰 SPIN: Starting spin wheel...');
    print('🎰 SPIN: Current spins today: $_spinsToday');

    // Ensure stream controller is initialized
    if (_selected == null || _selected!.isClosed) {
      _initializeStreamController();
    }

    setState(() {
      _isSpinning = true;
      _selectedCategory = null;
      _selectedChallenge = null;
      _categoryChallenges = [];
      _selectedChallengeId = null;
    });

    try {
      // Increment spin count first
      await ChallengeService.incrementSpinsToday();
      print('🎰 SPIN: Spin count incremented in Firestore');

      // Reload spin state to get updated count
      await _loadSpinState();
      print('🎰 SPIN: Spin state reloaded, new count: $_spinsToday');

      // Generate random spin result
      final index = Fortune.randomInt(0, _categories.length);
      _selected?.add(index);
      _lastSelectedIndex = index;

      print(
        '🎰 SPIN: Spin completed, selected category: ${_categories[index]['name']}',
      );
    } catch (e) {
      print('❌ SPIN ERROR: Failed to spin wheel: $e');
      // Reset spinning state on error
      setState(() {
        _isSpinning = false;
      });
    }
  }

  Map<String, dynamic>? _getSelectedCategory() {
    if (_lastSelectedIndex == null) return null;
    return _categories[_lastSelectedIndex!];
  }

  String _getResponsiveCategoryName(String fullName, double wheelSize, bool isIPhone) {
    // Use shorter names for iPhone
    if (isIPhone) {
      switch (fullName) {
        case 'Colorful Plates':
          return 'Colorful';
        case 'Quick Fix Snacks':
          return 'Quick Fix';
        case 'No Sugar Moments':
          return 'No Sugar';
        case 'Creative Combos':
          return 'Creative';
        case 'Mindful Eating':
          return 'Mindful';
        case 'Ingredient Spotlight':
          return 'Ingredient';
        case 'Other / Miscellaneous':
          return 'Other';
        default:
          return fullName;
      }
    }
    
    // Use shorter names for smaller wheels
    if (wheelSize < 300) {
      switch (fullName) {
        case 'Colorful Plates':
          return 'Colorful';
        case 'Quick Fix Snacks':
          return 'Quick Fix';
        case 'No Sugar Moments':
          return 'No Sugar';
        case 'Creative Combos':
          return 'Creative';
        case 'Mindful Eating':
          return 'Mindful';
        case 'Ingredient Spotlight':
          return 'Ingredient';
        case 'Other / Miscellaneous':
          return 'Other';
        default:
          return fullName;
      }
    }
    return fullName;
  }

  Future<void> _loadCategoryChallenges() async {
    if (_selectedCategory == null) return;

    print(
      '🎯 SPIN: Loading challenges for category: ${_selectedCategory!['id']}',
    );

    setState(() {
      _isLoadingChallenges = true;
    });

    // Ensure ModifierService is initialized
    await ModifierService.initialize();

    // Get challenges for this specific category
    final categoryChallenges = ModifierService.getChallengesByCategory(
      _selectedCategory!['id'],
    );
    print(
      '🎯 SPIN: Found ${categoryChallenges.length} challenges for category ${_selectedCategory!['id']}',
    );

    setState(() {
      _categoryChallenges = categoryChallenges;
      _selectedChallengeId = null;
      _selectedChallenge = null;
      _isLoadingChallenges = false;
    });
  }

  Future<void> _acceptChallenge() async {
    if (_selectedCategory == null || _selectedChallengeId == null) return;

    // Find the selected challenge
    final selectedChallenge = _categoryChallenges.firstWhere(
      (challenge) => challenge['id'] == _selectedChallengeId,
    );

    setState(() {
      _selectedChallenge = selectedChallenge;
    });

    // Navigate to modifier selection screen
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModifierSelectionScreen(
            challenge: selectedChallenge,
            category: _selectedCategory!,
          ),
        ),
      );

      // Refresh the state when returning from modifier selection
      await _loadSpinState();
    }
  }

  Future<void> _autoApproveOldSubmissions() async {
    try {
      print('🔄 SPIN: Checking for old pending submissions...');
      final submissions = await ChallengeSubmissionService.getAllSubmissions();
      bool updated = false;
      final now = DateTime.now();
      
      for (final submission in submissions) {
        if (submission.status == SubmissionStatus.pending &&
            now.difference(submission.submittedAt) >
                const Duration(minutes: 10)) {
          print('🔄 SPIN: Auto-approving submission: ${submission.id}');
          
          final approvedSubmission = ChallengeSubmission(
            id: submission.id,
            typeId: submission.typeId,
            challengeId: submission.challengeId,
            userId: submission.userId,
            userName: submission.userName,
            submissionTitle: submission.submissionTitle,
            submissionDescription: submission.submissionDescription,
            imageUrl: submission.imageUrl,
            videoUrl: submission.videoUrl,
            tags: submission.tags,
            submittedAt: submission.submittedAt,
            updatedAt: DateTime.now(),
            status: SubmissionStatus.approved,
            likesCount: submission.likesCount,
            commentsCount: submission.commentsCount,
            likedBy: submission.likedBy,
            metadata: submission.metadata,
          );
          
          await ChallengeSubmissionService.saveSubmission(approvedSubmission);
          updated = true;
        }
      }
      
      if (updated) {
        print('🔄 SPIN: Auto-approved old submissions successfully');
      } else {
        print('🔄 SPIN: No old submissions to auto-approve');
      }
    } catch (e) {
      print('❌ SPIN ERROR: Failed to auto-approve submissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isIPhone = screenSize.width < 400; // iPhone detection

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'SPIN THE WHEEL',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: isIPhone ? 20 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: AppColors.background, // Use your theme background
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Challenge Accepted Celebration - Show when challenge is accepted
                if (_challengeAccepted && !_isSpinning)
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: Column(
                      children: [
                        // Challenge Accepted Message - Clean & Compact
                        FutureBuilder<ChallengeEntry?>(
                          future: ChallengeService.getTodaysChallenge(),
                          builder: (context, snapshot) {
                            final challenge = snapshot.data;
                            String categoryName = 'Unknown';
                            String categoryEmoji = '🎯';

                            if (challenge != null) {
                              // Find the category details
                              final category = _categories.firstWhere(
                                (cat) => cat['id'] == challenge.category,
                                orElse: () => _categories.first,
                              );
                              categoryName = category['name'];
                              categoryEmoji = category['emoji'];
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondaryCTA.withOpacity(0.1),
                                    AppColors.primaryCTA.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.secondaryCTA,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryCTA.withOpacity(
                                      0.15,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Compact Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.secondaryCTA,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Challenge Accepted!',
                                        style: TextStyle(
                                          color: AppColors.secondaryCTA,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Category Info
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCTA.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primaryCTA.withOpacity(
                                          0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          categoryEmoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          categoryName,
                                          style: TextStyle(
                                            color: AppColors.primaryCTA,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Challenge Text
                                  if (challenge != null)
                                    Text(
                                      challenge.challengeText,
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                  const SizedBox(height: 8),

                                  // Motivational Text
                                  Text(
                                    'You\'ve got this! ✨',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                // Result display - Only show when spinning and category is selected
                if (_getSelectedCategory() != null &&
                    !_isSpinning &&
                    !_challengeAccepted)
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCTA.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primaryCTA,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCTA.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.secondaryCTA,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getSelectedCategory()!['emoji'],
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getSelectedCategory()!['name'],
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryCTA,
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getSelectedCategory()!['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Challenge Selection UI - Only show if challenge not accepted
                        if (!_challengeAccepted) ...[
                          if (_isLoadingChallenges)
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.primaryCTA,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Loading challenges...',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_categoryChallenges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryCTA.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedChallengeId,
                                  hint: Text(
                                    'Select a challenge...',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.primaryCTA,
                                  ),
                                  dropdownColor: AppColors.background,
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: _categoryChallenges.map((challenge) {
                                    return DropdownMenuItem<String>(
                                      value: challenge['id'],
                                      child: Text(
                                        challenge['text'],
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedChallengeId = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Accept Challenge Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _selectedChallengeId == null
                                  ? null
                                  : _acceptChallenge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedChallengeId == null
                                    ? Colors.grey
                                    : AppColors.secondaryCTA,
                                foregroundColor: AppColors.textDark,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _selectedChallengeId == null
                                    ? 'Select a challenge first'
                                    : 'Accept Challenge',
                                style: TextStyle(
                                  color: _selectedChallengeId == null
                                      ? Colors.white.withOpacity(0.8)
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Challenge Accepted Message - Enhanced Celebration
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondaryCTA.withOpacity(0.15),
                                  AppColors.primaryCTA.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.secondaryCTA,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryCTA.withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Celebration Icon with Animation
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCTA,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondaryCTA
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.celebration,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '🎉 CHALLENGE ACCEPTED! 🎉',
                                  style: TextStyle(
                                    color: AppColors.secondaryCTA,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Today you have accepted the challenge!',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Celebrate it and make it happen! 🌟',
                                  style: TextStyle(
                                    color: AppColors.textLight.withOpacity(0.8),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                // Motivational Quote
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCTA.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryCTA.withOpacity(
                                        0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: AppColors.primaryCTA,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'You\'ve got this! Time to shine! ✨',
                                          style: TextStyle(
                                            color: AppColors.primaryCTA,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                // Wheel container with pointer (FortuneWheel)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Make wheel responsive - use smaller size for iPhone
                    final wheelSize = isIPhone 
                        ? (constraints.maxWidth * 0.75).clamp(200.0, 350.0)  // Smaller for iPhone
                        : (constraints.maxWidth * 0.85).clamp(250.0, 400.0); // Existing logic
                    
                    final fontSize = isIPhone 
                        ? (wheelSize * 0.02).clamp(6.0, 10.0)  // Much smaller for iPhone
                        : (wheelSize * 0.025).clamp(8.0, 12.0); // Existing logic
                    
                    final emojiSize = isIPhone 
                        ? (wheelSize * 0.04).clamp(12.0, 18.0)  // Smaller emoji for iPhone
                        : (wheelSize * 0.06).clamp(16.0, 24.0); // Existing logic

                    return AbsorbPointer(
                      absorbing:
                          !_isSpinning, // Only allow interaction when spinning
                      child: SizedBox(
                        width: wheelSize,
                        height: wheelSize,
                        child: FortuneWheel(
                          selected: (_selected != null && !_selected!.isClosed) 
                              ? _selected!.stream 
                              : Stream.empty(),
                          animateFirst: false,
                          indicators: const <FortuneIndicator>[
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: TriangleIndicator(
                                color: Colors.yellowAccent,
                              ),
                            ),
                          ],
                          items: [
                            for (int i = 0; i < _categories.length; i++)
                              FortuneItem(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    isIPhone ? wheelSize * 0.01 : wheelSize * 0.02,  // Less padding for iPhone
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _categories[i]['emoji'],
                                        style: TextStyle(fontSize: emojiSize),
                                      ),
                                      SizedBox(
                                        height: isIPhone ? wheelSize * 0.005 : wheelSize * 0.008,  // Less spacing for iPhone
                                      ),
                                      Flexible(
                                        child: Text(
                                          _getResponsiveCategoryName(
                                            _categories[i]['name'],
                                            wheelSize,
                                            isIPhone,
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize,
                                            height: 1.1, // Tighter line height
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                style: FortuneItemStyle(
                                  color:
                                      _segmentColors[i % _segmentColors.length],
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                ),
                              ),
                          ],
                          onAnimationEnd: () {
                            setState(() {
                              _isSpinning = false;
                              _selectedCategory = _getSelectedCategory();
                            });
                            // Load challenges for the selected category
                            _loadCategoryChallenges();
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                // Spins left message - Only show if no challenge accepted
                if (!_challengeAccepted)
                  if (_spinsToday < maxSpinsPerDay)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text.rich(
                        TextSpan(
                          text: 'You have ',
                          style: TextStyle(
                            color: AppColors.primaryCTA,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: '${maxSpinsPerDay - _spinsToday}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryCTA,
                              ),
                            ),
                            const TextSpan(text: ' spins left today.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No spins left for today.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                const SizedBox(height: 24),

                // Spin button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isSpinning ||
                              _spinsToday >= maxSpinsPerDay ||
                              _challengeAccepted
                          ? null
                          : _spinWheel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSpinning ||
                                _spinsToday >= maxSpinsPerDay ||
                                _challengeAccepted
                            ? Colors.grey
                            : AppColors.primaryCTA,
                        foregroundColor: AppColors.textLight,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isSpinning ? 0 : 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (_isSpinning)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.rotate_right, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _isSpinning
                                ? 'Spinning...'
                                : _spinsToday >= maxSpinsPerDay
                                ? 'No Spins Left'
                                : _challengeAccepted
                                ? 'Challenge Accepted'
                                : 'Spin the Wheel',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
