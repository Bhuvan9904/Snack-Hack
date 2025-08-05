import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/badge_service.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color color;
  final bool earned;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.earned = false,
  });
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  late Future<List<String>> _earnedBadgesFuture;

  @override
  void initState() {
    super.initState();
    _earnedBadgesFuture = BadgeService.getEarnedBadges();
  }

  List<Badge> _allBadges(List<String> earnedBadgeIds) {
    final badgeInfo = BadgeService.getBadgeInfo();
    final List<Badge> badges = [];

    badgeInfo.forEach((badgeId, info) {
      badges.add(
        Badge(
          id: badgeId,
          name: info['name'] as String,
          description: info['description'] as String,
          icon: info['icon'] as String,
          color: Color(info['color'] as int),
          earned: earnedBadgeIds.contains(badgeId),
        ),
      );
    });

    // Sort badges: earned first, then by name
    badges.sort((a, b) {
      if (a.earned != b.earned) {
        return b.earned ? 1 : -1;
      }
      return a.name.compareTo(b.name);
    });

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: AppColors.primaryCTA, size: 20),
            const SizedBox(width: 10),
            Text(
              'BADGES',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Stats header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: FutureBuilder<List<String>>(
                  future: _earnedBadgesFuture,
                  builder: (context, snapshot) {
                    final earnedCount = snapshot.data?.length ?? 0;
                    final totalCount = BadgeService.getBadgeInfo().length;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Badge Progress',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$earnedCount of $totalCount earned',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCTA,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${((earnedCount / totalCount) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _earnedBadgesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final earnedBadgeIds = snapshot.data ?? <String>[];
                    final badges = _allBadges(earnedBadgeIds);
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            boxShadow: badge.earned
                                ? [
                                    BoxShadow(
                                      color: badge.color.withOpacity(0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: _buildBadgeCard(badge),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return Card(
      color: badge.earned ? badge.color.withOpacity(0.15) : AppColors.secondary,
      elevation: badge.earned ? 6 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      backgroundColor: badge.earned
                          ? badge.color
                          : Colors.grey[400],
                      radius: 28,
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    if (badge.earned)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.check_circle,
                            color: badge.color,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  badge.name,
                  style: TextStyle(
                    color: badge.earned ? badge.color : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  badge.description,
                  style: TextStyle(
                    color: badge.earned
                        ? AppColors.textLight
                        : Colors.grey[500],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
