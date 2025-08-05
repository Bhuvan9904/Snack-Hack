import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/user_service.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:snack_hack_app/features/groups/user_discovery_screen.dart';
import 'package:snack_hack_app/features/challenge_submission/challenge_submission_screen.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<GroupSubmission> _submissions = [];
  ChallengeEntry? _currentChallenge;
  bool _isLoading = true;
  bool _hasUserSubmitted = false;
  Map<String, String> _userNames = {}; // Cache for user names

  // Leaderboard data
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = true;

  // Scroll controller for tracking scroll position
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add scroll listener to show/hide back to top button
    _scrollController.addListener(() {
      setState(() {
        _showBackToTopButton =
            _scrollController.offset > 200; // Reduced threshold
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('📸 GROUP DETAIL: Loading data for group: ${widget.group.name}');
    setState(() => _isLoading = true);

    try {
      // Load current challenge and submissions
      final challenge = await ChallengeService.getTodaysChallenge();
      final submissions = await GroupService.getGroupSubmissions(
        widget.group.id,
      );

      // Check if current user has submitted
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final userSubmission = submissions
          .where((s) => s.userId == currentUserId)
          .isNotEmpty;

      // Load user names for all submissions
      await _loadUserNames(submissions);

      setState(() {
        _currentChallenge = challenge;
        _submissions = submissions;
        _hasUserSubmitted = userSubmission;
        _isLoading = false;
      });

      print(
        '📸 GROUP DETAIL: Loaded ${submissions.length} submissions, challenge: ${challenge?.challengeText}',
      );
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: $e');
      setState(() => _isLoading = false);
    }

    // Load leaderboard data
    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    print(
      '🏆 GROUP DETAIL: Loading leaderboard for group: ${widget.group.name}',
    );
    setState(() => _isLoadingLeaderboard = true);

    try {
      final leaderboard = await GroupService.getGroupLeaderboard(
        widget.group.id,
      );

      // Load user names for leaderboard
      for (final entry in leaderboard) {
        final userId = entry['userId'] as String;
        if (!_userNames.containsKey(userId)) {
          final userData = await UserService.getUserById(userId);
          if (userData != null) {
            _userNames[userId] = userData['name'] ?? 'Unknown User';
          } else {
            _userNames[userId] = 'Unknown User';
          }
        }
      }

      setState(() {
        _leaderboard = leaderboard;
        _isLoadingLeaderboard = false;
      });

      print(
        '🏆 GROUP DETAIL: Loaded leaderboard with ${leaderboard.length} users',
      );
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: Failed to load leaderboard: $e');
      setState(() => _isLoadingLeaderboard = false);
    }
  }

  Future<void> _loadUserNames(List<GroupSubmission> submissions) async {
    try {
      final uniqueUserIds = submissions.map((s) => s.userId).toSet();

      for (final userId in uniqueUserIds) {
        if (!_userNames.containsKey(userId)) {
          final userData = await UserService.getUserById(userId);
          if (userData != null) {
            _userNames[userId] = userData['name'] ?? 'Unknown User';
          } else {
            _userNames[userId] = 'Unknown User';
          }
        }
      }
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: Failed to load user names: $e');
    }
  }

  Future<void> _voteOnSubmission(
    GroupSubmission submission,
    String voteType,
  ) async {
    try {
      print(
        '🗳️ GROUP DETAIL: Voting $voteType on submission: ${submission.id}',
      );

      await GroupService.voteOnSubmission(
        submissionId: submission.id,
        groupId: widget.group.id,
        voteType: voteType,
      );

      // Reload submissions to get updated vote counts
      await _loadData();

      // Also refresh leaderboard since points may have changed
      await _loadLeaderboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vote recorded! ${voteType == 'nailed_it' ? '🎉' : '👍'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSubmission() {
    if (_currentChallenge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No challenge available. Spin for a challenge first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeSubmissionScreen(
          challengeText: _currentChallenge!.challengeText,
          date: _currentChallenge!.date,
        ),
      ),
    ).then((_) async {
      // Reload data and leaderboard after submission
      await _loadData();
      await _loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.group.name,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.people), onPressed: _showMembers),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Modern Group Header Section
                _buildModernGroupHeader(),

                // Challenge Section
                _buildChallengeSection(),

                // Submit button (if user hasn't submitted yet)
                if (_currentChallenge != null && !_hasUserSubmitted) ...[
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ],

                // Leaderboard Section
                _buildLeaderboardSection(),

                // Submission Header
                _buildSubmissionHeader(),

                const SizedBox(height: 16),

                // Submissions list
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryCTA,
                          ),
                        ),
                      )
                    : _submissions.isEmpty
                    ? _buildEmptySubmissions()
                    : Column(
                        children: _submissions.map((submission) {
                          return _buildSubmissionCard(submission);
                        }).toList(),
                      ),

                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ),

          // Sticky header that appears when scrolling - Fixed positioning
          if (_showBackToTopButton)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(elevation: 8, child: _buildStickyHeader()),
            ),
        ],
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: AppColors.primaryCTA,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Group name and member count
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCTA.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: AppColors.primaryCTA,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_submissions.length} challenges • ${widget.group.members.length} members',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            Row(
              children: [
                // Current challenge indicator
                if (_currentChallenge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCTA.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primaryCTA,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.primaryCTA,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: 8),

                // Quick action buttons
                // Removed redundant members button - using AppBar button instead
                if (widget.group.isAdmin(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ))
                  IconButton(
                    onPressed: _navigateToUserDiscovery,
                    icon: const Icon(
                      Icons.person_add,
                      color: AppColors.textLight,
                    ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGroupHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.95),
            AppColors.secondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Group name and member count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.group.description,
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCTA.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryCTA.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, color: AppColors.primaryCTA, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.group.members.length}/${widget.group.maxMembers}',
                        style: const TextStyle(
                          color: AppColors.primaryCTA,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Group stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    'Created',
                    _formatDate(widget.group.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.emoji_events,
                    'Challenges',
                    '${_submissions.length}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.trending_up,
                    'Active',
                    widget.group.members.length > 1 ? 'Yes' : 'No',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            if (widget.group.isAdmin(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            )) ...[
              // Admin actions
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Add Members',
                  color: AppColors.primaryCTA,
                  onTap: _navigateToUserDiscovery,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.delete_forever,
                  label: 'Delete Group',
                  color: Colors.red,
                  onTap: _showDeleteConfirmation,
                  isOutlined: true,
                ),
              ),
            ] else ...[
              // Member actions
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.exit_to_app,
                  label: 'Leave Group',
                  color: Colors.orange,
                  onTap: _showLeaveConfirmation,
                  isOutlined: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryCTA, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Column(
      children: [
        // Challenge header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primaryCTA,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Challenge',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_currentChallenge != null)
                Text(
                  _formatDate(_currentChallenge!.date),
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 14,
                  ),
                )
              else
                Text(
                  'No challenge today',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Challenge text
        if (_currentChallenge != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _currentChallenge!.challengeText,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'No challenge today. Spin for a challenge!',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      children: [
        // Leaderboard header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.leaderboard, color: AppColors.secondaryCTA, size: 20),
              const SizedBox(width: 8),
              Text(
                'Group Leaderboard',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isLoadingLeaderboard)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppColors.secondaryCTA,
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  '${_leaderboard.length} members',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Leaderboard content
        if (_isLoadingLeaderboard)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryCTA),
            ),
          )
        else if (_leaderboard.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  color: AppColors.textLight.withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No submissions yet',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to submit a challenge!',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.95),
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
              children: _leaderboard.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final userId = user['userId'] as String;
                final points = user['points'] as int;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isCurrentUser = userId == currentUserId;

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: index < _leaderboard.length - 1
                          ? BorderSide(
                              color: AppColors.textLight.withOpacity(0.1),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(index + 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isCurrentUser
                                ? 'You'
                                : _userNames[userId] ?? 'Unknown User',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCTA.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: AppColors.primaryCTA,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: _getRankColor(index + 1),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$points pts',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return AppColors.primaryCTA;
    }
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToSubmission,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Submit Your Challenge'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCTA,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryCTA.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryCTA.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: AppColors.primaryCTA, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Challenge Feed',
                  style: TextStyle(
                    color: AppColors.primaryCTA,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_submissions.length} submissions',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(GroupSubmission submission) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnSubmission = submission.userId == currentUserId;
    final hasUserVoted = submission.hasUserVoted(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        color: AppColors.secondary.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isOwnSubmission
                ? AppColors.primaryCTA.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info and timestamp
                Row(
                  children: [
                    // User avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isOwnSubmission
                            ? AppColors.primaryCTA.withOpacity(0.2)
                            : AppColors.secondaryCTA.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOwnSubmission
                              ? AppColors.primaryCTA.withOpacity(0.5)
                              : AppColors.secondaryCTA.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (isOwnSubmission
                                  ? 'You'
                                  : _userNames[submission.userId] ??
                                        'Unknown User')
                              .substring(0, 2)
                              .toUpperCase(),
                          style: TextStyle(
                            color: isOwnSubmission
                                ? AppColors.primaryCTA
                                : AppColors.secondaryCTA,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User name and timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isOwnSubmission
                                    ? 'You'
                                    : _userNames[submission.userId] ??
                                          'Unknown User',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isOwnSubmission) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCTA.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      color: AppColors.primaryCTA,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(submission.submittedAt),
                            style: TextStyle(
                              color: AppColors.textLight.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Challenge badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCTA.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: AppColors.primaryCTA,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Challenge',
                            style: TextStyle(
                              color: AppColors.primaryCTA,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Challenge content
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textLight.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge title
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.primaryCTA,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              submission.title,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (submission.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          submission.description,
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],

                      // Image (if available)
                      if (submission.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(submission.imageUrl),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: AppColors.textLight.withOpacity(
                                        0.5,
                                      ),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not found',
                                      style: TextStyle(
                                        color: AppColors.textLight.withOpacity(
                                          0.5,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Modifiers
                      if (submission.modifiers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Modifiers:',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: submission.modifiers.map((modifier) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCTA.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryCTA.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                modifier,
                                style: TextStyle(
                                  color: AppColors.primaryCTA,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Voting section
                Row(
                  children: [
                    // Vote counts
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${submission.nailedItVotes}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.thumb_up_outlined,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${submission.closeTryVotes}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Total votes badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCTA.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${submission.totalVotes} votes',
                        style: TextStyle(
                          color: AppColors.secondaryCTA,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Voting buttons section - Made more prominent
                if (!isOwnSubmission && !hasUserVoted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: AppColors.primaryCTA,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rate this challenge:',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _voteOnSubmission(submission, 'nailed_it'),
                                icon: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Nailed it! 🎉',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryCTA,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _voteOnSubmission(submission, 'close_try'),
                                icon: const Icon(
                                  Icons.favorite_border,
                                  color: AppColors.secondaryCTA,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Close try 👍',
                                  style: TextStyle(
                                    color: AppColors.secondaryCTA,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondaryCTA,
                                  side: const BorderSide(
                                    color: AppColors.secondaryCTA,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Show voted message if user has already voted
                if (!isOwnSubmission && hasUserVoted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCTA.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryCTA.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryCTA,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You voted ${submission.votes[currentUserId] == 'nailed_it' ? '"Nailed it!" 🎉' : '"Close try!" 👍'}',
                            style: TextStyle(
                              color: AppColors.primaryCTA,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySubmissions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textLight.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryCTA.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: AppColors.primaryCTA,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No challenges yet',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to submit a challenge and inspire your group!',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryCTA.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryCTA.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb, color: AppColors.primaryCTA, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Spin for a challenge first!',
                  style: TextStyle(
                    color: AppColors.primaryCTA,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: Row(
          children: [
            Icon(Icons.people, color: AppColors.primaryCTA),
            const SizedBox(width: 8),
            const Text(
              'Group Members',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Member count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryCTA.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.group.members.length}/${widget.group.maxMembers} members',
                  style: const TextStyle(
                    color: AppColors.primaryCTA,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members list
              if (widget.group.members.isEmpty)
                const Text(
                  'No members yet',
                  style: TextStyle(color: AppColors.textLight),
                )
              else
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadMemberNames(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryCTA,
                        ),
                      );
                    }

                    final memberNames =
                        snapshot.data ?? <Map<String, dynamic>>[];

                    return Column(
                      children: widget.group.members.map((memberId) {
                        final isAdmin = widget.group.admins.contains(memberId);
                        final isCurrentUser =
                            memberId == FirebaseAuth.instance.currentUser?.uid;
                        final memberName =
                            memberNames.firstWhere(
                                  (member) => member['id'] == memberId,
                                  orElse: () => {'name': 'Unknown User'},
                                )['name']
                                as String;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryCTA.withOpacity(
                              0.2,
                            ),
                            child: Text(
                              memberName.substring(0, 2).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryCTA,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            isCurrentUser ? 'You' : memberName,
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                          subtitle: Text(
                            isAdmin ? 'Admin' : 'Member',
                            style: TextStyle(
                              color: isAdmin
                                  ? Colors.orange
                                  : AppColors.textLight.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          trailing: isCurrentUser
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCTA.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      color: AppColors.primaryCTA,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMemberNames() async {
    try {
      final memberNames = <Map<String, dynamic>>[];

      for (final memberId in widget.group.members) {
        final userData = await UserService.getUserById(memberId);
        if (userData != null) {
          memberNames.add({
            'id': memberId,
            'name': userData['name'] ?? 'Unknown User',
          });
        } else {
          memberNames.add({'id': memberId, 'name': 'Unknown User'});
        }
      }

      return memberNames;
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: Failed to load member names: $e');
      return widget.group.members
          .map((memberId) => {'id': memberId, 'name': 'Unknown User'})
          .toList();
    }
  }

  void _navigateToUserDiscovery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDiscoveryScreen(group: widget.group),
      ),
    ).then((_) => _loadData());
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Delete Group',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${widget.group.name}"?',
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. All group data, submissions, and member information will be permanently deleted.',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      await GroupService.deleteGroup(widget.group.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${widget.group.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to groups list
      }
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Leave Group',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${widget.group.name}"?',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      await GroupService.leaveGroup(widget.group.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You left "${widget.group.name}" successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to groups list
      }
    } catch (e) {
      print('❌ GROUP DETAIL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return _formatDate(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
