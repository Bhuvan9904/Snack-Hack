import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStats {
  final int points;
  final int streak;
  final List<String> earnedBadgeIds;

  AppStats({
    required this.points,
    required this.streak,
    required this.earnedBadgeIds,
  });

  AppStats copyWith({int? points, int? streak, List<String>? earnedBadgeIds}) {
    return AppStats(
      points: points ?? this.points,
      streak: streak ?? this.streak,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
    );
  }
}

class AppStatsNotifier extends StateNotifier<AppStats> {
  AppStatsNotifier()
    : super(AppStats(points: 0, streak: 0, earnedBadgeIds: []));

  void setStats({
    required int points,
    required int streak,
    required List<String> badges,
  }) {
    state = AppStats(points: points, streak: streak, earnedBadgeIds: badges);
  }

  // Optionally, add methods to update individual fields
}

final appStatsProvider = StateNotifierProvider<AppStatsNotifier, AppStats>((
  ref,
) {
  return AppStatsNotifier();
});
