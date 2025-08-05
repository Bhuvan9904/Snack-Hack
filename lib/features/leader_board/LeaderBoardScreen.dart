export 'package:snack_hack_app/features/leader_board/LeaderBoardScreen.dart'
    show LeaderBoardScreen, _LeaderBoardScreenState;
import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snack_hack_app/providers/app_stats_provider.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/user_service.dart';
import 'package:snack_hack_app/core/services/badge_service.dart';
import 'package:snack_hack_app/data/models/group_model.dart';

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

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  List<Group> _userGroups = [];
  Map<String, List<Map<String, dynamic>>> _groupLeaderboards = {};
  bool _isLoading = true;
  String _selectedGroupId = '';
  Map<String, String> _userNames = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    _loadGroupsAndLeaderboards();
  }

  Future<void> _loadGroupsAndLeaderboards() async {
    print('🏆 LEADERBOARD: Loading groups and leaderboards...');
    setState(() => _isLoading = true);

    try {
      // Load user's groups
      final groups = await GroupService.getUserGroups();

      // Load leaderboards for each group
      final leaderboards = <String, List<Map<String, dynamic>>>{};
      for (final group in groups) {
        try {
          final leaderboard = await GroupService.getGroupLeaderboard(group.id);
          leaderboards[group.id] = leaderboard;
        } catch (e) {
          print(
            '❌ LEADERBOARD ERROR: Failed to load leaderboard for group ${group.name}: $e',
          );
          leaderboards[group.id] = [];
        }
      }

      // Load user names for all leaderboards
      await _loadUserNames(leaderboards);

      setState(() {
        _userGroups = groups;
        _groupLeaderboards = leaderboards;
        _selectedGroupId = groups.isNotEmpty ? groups.first.id : '';
        _isLoading = false;
      });

      print('🏆 LEADERBOARD: Loaded ${groups.length} groups with leaderboards');
    } catch (e) {
      print('❌ LEADERBOARD ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserNames(
    Map<String, List<Map<String, dynamic>>> leaderboards,
  ) async {
    try {
      final allUserIds = <String>{};

      // Collect all unique user IDs from all leaderboards
      for (final leaderboard in leaderboards.values) {
        for (final user in leaderboard) {
          allUserIds.add(user['userId'] as String);
        }
      }

      // Load user names for all unique user IDs
      for (final userId in allUserIds) {
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
      print('❌ LEADERBOARD ERROR: Failed to load user names: $e');
    }
  }

  // Public refresh method that can be called from outside
  Future<void> refresh() async {
    print('🏆 LEADERBOARD: Refreshing leaderboards...');
    await _loadGroupsAndLeaderboards();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(appStatsProvider);
    print(
      'LeaderBoardScreen stats: points=${stats.points}, streak=${stats.streak}, badges=${stats.earnedBadgeIds}',
    );

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
            Icon(Icons.leaderboard, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'LEADERBOARD',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCTA),
            )
          : RefreshIndicator(
              onRefresh: _loadGroupsAndLeaderboards,
              color: AppColors.primaryCTA,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Your Stats Card
                    _buildYourStatsCard(stats),
                    const SizedBox(height: 24),

                    // Group Leaderboards
                    if (_userGroups.isNotEmpty) ...[
                      _buildGroupLeaderboardsSection(stats),
                      const SizedBox(height: 24),
                    ],

                    // Badges Section
                    _buildBadgesSection(stats),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildYourStatsCard(AppStats stats) {
    return Card(
      color: AppColors.secondary.withOpacity(0.95),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: AppColors.primaryCTA, size: 24),
                const SizedBox(width: 8),
                Text(
                  "Your Stats",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Points",
                    stats.points.toString(),
                    Icons.emoji_events,
                    AppColors.primaryCTA,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Streak",
                    "${stats.streak} days",
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Badges",
                    stats.earnedBadgeIds.length.toString(),
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Rank",
                    _getUserRank(stats.points),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupLeaderboardsSection(AppStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Group Leaderboards",
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Group selector
        if (_userGroups.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryCTA.withOpacity(0.3)),
            ),
            child: DropdownButton<String>(
              value: _selectedGroupId,
              onChanged: (value) {
                setState(() => _selectedGroupId = value!);
              },
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryCTA),
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: _userGroups.map((group) {
                return DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Selected group leaderboard
        if (_selectedGroupId.isNotEmpty &&
            _groupLeaderboards.containsKey(_selectedGroupId))
          _buildLeaderboardList(
            _groupLeaderboards[_selectedGroupId]!,
            stats.points,
            isGroup: true,
          ),
      ],
    );
  }

  Widget _buildBadgesSection(AppStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Badges",
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildBadgesRow(stats.earnedBadgeIds),
        const SizedBox(height: 16),
        Text(
          "Keep going! Complete more challenges to earn more badges.",
          style: TextStyle(
            color: AppColors.textLight.withOpacity(0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textLight.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    int userPoints, {
    bool isGroup = false,
  }) {
    if (leaderboard.isEmpty) {
      return Card(
        color: AppColors.secondary.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.leaderboard_outlined,
                color: AppColors.textLight.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "No submissions yet",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Be the first to submit a challenge!",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.secondary.withOpacity(0.95),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: leaderboard.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          final points = user['points'] as int;
          final isCurrentUser = points == userPoints; // Simplified check

          return ListTile(
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
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  _userNames[user['userId']] ?? 'Unknown User',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
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
              ],
            ),
            trailing: Text(
              '${points} pts',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
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

  String _getUserRank(int points) {
    // Simplified ranking logic
    if (points >= 100) return "Elite";
    if (points >= 50) return "Pro";
    if (points >= 20) return "Intermediate";
    if (points >= 10) return "Beginner";
    return "Newbie";
  }

  // Get badge information from BadgeService
  List<Badge> getAllBadges() {
    final badgeInfo = BadgeService.getBadgeInfo();
    return badgeInfo.entries.map((entry) {
      final info = entry.value;
      return Badge(
        id: entry.key,
        name: info['name'] as String,
        description: info['description'] as String,
        icon:
            Icons.star, // Fallback icon since we're using emoji in BadgeService
        color: Color(info['color'] as int),
      );
    }).toList();
  }

  Widget _buildBadgesRow(List<String> earnedBadgeIds) {
    final badgeInfo = BadgeService.getBadgeInfo();
    final earnedBadges = badgeInfo.entries
        .where((entry) => earnedBadgeIds.contains(entry.key))
        .toList();

    if (earnedBadges.isEmpty) {
      return Card(
        color: AppColors.secondary.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: AppColors.textLight.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "No badges yet",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Complete challenges to earn your first badge!",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.secondary.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: earnedBadges.map((entry) {
            final badge = entry.value;
            final color = Color(badge['color'] as int);
            return Tooltip(
              message: '${badge['name']}: ${badge['description']}',
              child: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                radius: 28,
                child: Text(
                  badge['icon'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
