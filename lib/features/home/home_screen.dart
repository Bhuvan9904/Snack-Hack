import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:snack_hack_app/features/challenge_submission/challenge_submission_screen.dart';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';
import 'package:snack_hack_app/features/challenge_submission/submission_history_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snack_hack_app/providers/app_stats_provider.dart';
import 'package:snack_hack_app/core/services/badge_service.dart';
import 'package:go_router/go_router.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  ChallengeEntry? _todaysChallenge;
  int _streak = 0;
  int _points = 0;
  bool _loading = true;
  bool _proofSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🏠 HOME: Loading data...');

      // Auto-approve old pending submissions first
      await _autoApproveOldSubmissions();

      final challenge = await ChallengeService.getTodaysChallenge();
      final streak = await ChallengeService.getStreak();
      final points = await ChallengeService.getPoints();
      final badges = await BadgeService.getEarnedBadges();

      print(
        '🏠 HOME: Data loaded - challenge: ${challenge?.challengeText}, streak: $streak, points: $points, badges: ${badges.length}',
      );

      bool proofSubmitted = false;
      if (challenge != null) {
        final submission =
            await ChallengeSubmissionService.getSubmissionForDate(
              challenge.date,
            );
        proofSubmitted = submission != null;
      }

      if (mounted) {
        setState(() {
          _todaysChallenge = challenge;
          _streak = streak;
          _points = points;
          _proofSubmitted = proofSubmitted;
          _loading = false;
        });

        // Update Riverpod provider
        ref
            .read(appStatsProvider.notifier)
            .setStats(points: points, streak: streak, badges: badges);

        print('🏠 HOME: UI updated successfully');
      }
    } catch (e) {
      print('❌ HOME ERROR: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          // Set default values on error
          _todaysChallenge = null;
          _streak = 0;
          _points = 0;
          _proofSubmitted = false;
        });
      }
    }
  }

  Future<void> _autoApproveOldSubmissions() async {
    try {
      print('🔄 HOME: Checking for old pending submissions...');
      final submissions = await ChallengeSubmissionService.getAllSubmissions();
      bool updated = false;
      final now = DateTime.now();
      
      for (final submission in submissions) {
        if (submission.status == SubmissionStatus.pending &&
            now.difference(submission.submittedAt) >
                const Duration(minutes: 10)) {
          print('🔄 HOME: Auto-approving submission: ${submission.id}');
          
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
        print('🔄 HOME: Auto-approved old submissions successfully');
      } else {
        print('🔄 HOME: No old submissions to auto-approve');
      }
    } catch (e) {
      print('❌ HOME ERROR: Failed to auto-approve submissions: $e');
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  /// Convert errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission-denied')) {
      return 'Unable to load data. Please try again.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else {
      return 'Failed to load data. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCTA),
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
            Icon(Icons.home, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'SNACKHACK',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playful icon header
            Center(
              child: Icon(
                Icons.emoji_food_beverage,
                size: 48,
                color: AppColors.primaryCTA,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Welcome to SnackHack!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.secondary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "Today's Challenge",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_todaysChallenge == null)
                      Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 56,
                            color: AppColors.secondaryCTA.withOpacity(0.7),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No challenge yet! Spin to get started.",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      Text(
                        _todaysChallenge!.challengeText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),
                    if (_todaysChallenge != null &&
                        !_todaysChallenge!.completed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await ChallengeService.completeTodaysChallenge();
                            await _loadData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCTA,
                            foregroundColor: AppColors.textLight,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Mark as Completed"),
                        ),
                      ),
                    if (_todaysChallenge != null &&
                        _todaysChallenge!.completed &&
                        !_proofSubmitted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChallengeSubmissionScreen(
                                  challengeText:
                                      _todaysChallenge!.challengeText,
                                  date: _todaysChallenge!.date,
                                  modifiers: _todaysChallenge!.modifiers,
                                ),
                              ),
                            );
                            await _loadData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCTA,
                            foregroundColor: AppColors.textLight,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Submit Proof"),
                        ),
                      ),
                    if (_todaysChallenge != null &&
                        _todaysChallenge!.completed &&
                        _proofSubmitted)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Proof submitted!",
                          style: TextStyle(
                            color: AppColors.primaryCTA,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 90,
                    child: Card(
                      color: AppColors.secondary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: ListTile(
                          leading: const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                          ),
                          title: Text(
                            "Streak: $_streak days",
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 90,
                    child: Card(
                      color: AppColors.secondary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: ListTile(
                          leading: const Icon(
                            Icons.emoji_events,
                            color: AppColors.secondaryCTA,
                          ),
                          title: Text(
                            "Points: $_points",
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  // Switch to Spin tab in NavScreen
                  context.go('/nav?tab=1');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCTA,
                  foregroundColor: AppColors.textLight,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Spin Challenge"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  final submissions =
                      await ChallengeSubmissionService.getAllSubmissions();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SubmissionHistoryScreen(submissions: submissions),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryCTA,
                  side: const BorderSide(
                    color: AppColors.secondaryCTA,
                    width: 2,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Submission History'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
