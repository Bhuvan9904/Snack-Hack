import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';
import 'dart:convert';

class ChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Check if current user is a guest
  static Future<bool> _isGuestUser() async {
    return _userId == null && await GuestUserService.isGuestSessionValid();
  }

  /// Save today's challenge (when spun/accepted)
  static Future<void> saveTodaysChallenge(ChallengeEntry entry) async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) {
      print('❌ CHALLENGE: No user ID available');
      return;
    }

    print('🎯 CHALLENGE: Saving today\'s challenge...');
    print('   - Challenge: ${entry.challengeText}');
    print('   - Date: ${_dateKey(entry.date)}');
    print('   - User ID: $_userId');
    print('   - Is Guest: $isGuest');

    if (isGuest) {
      // Guest user - save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _dateKey(entry.date);
      await prefs.setString(
        'guest_challenge_$todayKey',
        jsonEncode(entry.toMap()),
      );
      print('✅ CHALLENGE: Guest challenge saved successfully!');
    } else {
      // Firebase user - save to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenges')
          .doc(_dateKey(entry.date))
          .set(entry.toMap());
      print('✅ CHALLENGE: Challenge saved successfully!');
    }
  }

  /// Get today's challenge, or null if not set
  static Future<ChallengeEntry?> getTodaysChallenge() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return null;

    if (isGuest) {
      // Guest user - get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _dateKey(DateTime.now());
      final challengeData = prefs.getString('guest_challenge_$todayKey');

      if (challengeData == null) return null;

      try {
        final challengeMap = jsonDecode(challengeData) as Map<String, dynamic>;
        return ChallengeEntry.fromMap(challengeMap);
      } catch (e) {
        print('❌ CHALLENGE ERROR: Failed to parse guest challenge data: $e');
        return null;
      }
    } else {
      // Firebase user - get from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenges')
          .doc(_dateKey(DateTime.now()))
          .get();

      if (!doc.exists) return null;
      return ChallengeEntry.fromMap(doc.data()!);
    }
  }

  /// Get all user challenges
  static Future<List<ChallengeEntry>> getUserChallenges() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return [];

    print('🎯 CHALLENGE: Getting all user challenges...');
    final querySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('challenges')
        .get();

    final challenges = querySnapshot.docs
        .map((doc) => ChallengeEntry.fromMap(doc.data()))
        .toList();

    print('🎯 CHALLENGE: Found ${challenges.length} challenges');
    return challenges;
  }

  /// Mark today's challenge as completed and update streak/points
  static Future<void> completeTodaysChallenge() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) {
      print('❌ CHALLENGE: No user ID available for completion');
      return;
    }

    print('🎯 CHALLENGE: Completing today\'s challenge...');
    final todayKey = _dateKey(DateTime.now());
    final challengeDoc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('challenges')
        .doc(todayKey)
        .get();

    if (!challengeDoc.exists) {
      print('❌ CHALLENGE: No challenge found for today');
      return;
    }

    print('✅ CHALLENGE: Found challenge, marking as completed...');
    // Mark as completed
    final entry = ChallengeEntry.fromMap(challengeDoc.data()!);
    final updatedEntry = ChallengeEntry(
      challengeText: entry.challengeText,
      date: entry.date,
      modifiers: entry.modifiers,
      completed: true,
      category: entry.category,
      difficulty: entry.difficulty,
      id: entry.id,
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('challenges')
        .doc(todayKey)
        .set(updatedEntry.toMap());

    print('🎯 CHALLENGE: Updating user progress...');
    // Update user progress
    final userDoc = await _firestore.collection('users').doc(_userId).get();
    final userData = userDoc.data() ?? {};

    int streak = userData['streak'] ?? 0;
    int points = userData['points'] ?? 0;

    final lastCompletedDateStr = userData['lastCompletedDate'];
    if (lastCompletedDateStr != null) {
      final lastCompletedDate = DateTime.parse(lastCompletedDateStr);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      if (_isSameDate(lastCompletedDate, yesterday)) {
        streak += 1;
      } else if (!_isSameDate(lastCompletedDate, DateTime.now())) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    points += 10; // +10 points for completion

    print('📊 CHALLENGE: Progress update:');
    print('   - Old streak: ${userData['streak'] ?? 0} → New streak: $streak');
    print('   - Old points: ${userData['points'] ?? 0} → New points: $points');

    await _firestore.collection('users').doc(_userId).update({
      'streak': streak,
      'points': points,
      'lastCompletedDate': _dateKey(DateTime.now()),
    });

    print('✅ CHALLENGE: Challenge completed and progress updated!');
  }

  /// Get current streak
  static Future<int> getStreak() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return 0;

    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.data()?['streak'] ?? 0;
  }

  /// Get current points
  static Future<int> getPoints() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return 0;

    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.data()?['points'] ?? 0;
  }

  /// Get number of spins used today
  static Future<int> getSpinsToday() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && isGuest) {
      // Guest user - use SharedPreferences
      print('🎰 SPIN: Guest user detected, using SharedPreferences');
      try {
        final prefs = await SharedPreferences.getInstance();
        final todayKey = _dateKey(DateTime.now());
        final spins = prefs.getInt('spins_$todayKey') ?? 0;
        print('🎰 SPIN: Guest spins for today: $spins');
        return spins;
      } catch (e) {
        print('❌ SPIN ERROR: Failed to get guest spins: $e');
        return 0;
      }
    }

    try {
      final todayKey = _dateKey(DateTime.now());
      print('🎰 SPIN: Getting spins for date: $todayKey, user: $_userId');

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('spins')
          .doc(todayKey)
          .get();

      final spins = doc.data()?['count'] ?? 0;
      print('🎰 SPIN: Found $spins spins for today');
      return spins;
    } catch (e) {
      print('❌ SPIN ERROR: Failed to get spins today: $e');
      return 0;
    }
  }

  /// Increment today's spin count by 1
  static Future<void> incrementSpinsToday() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && isGuest) {
      // Guest user - use SharedPreferences
      print('🎰 SPIN: Guest user detected, incrementing in SharedPreferences');
      try {
        final prefs = await SharedPreferences.getInstance();
        final todayKey = _dateKey(DateTime.now());

        int spins = prefs.getInt('spins_$todayKey') ?? 0;
        print('🎰 SPIN: Guest current spins: $spins');

        spins += 1;
        print('🎰 SPIN: Guest new spins count: $spins');

        await prefs.setInt('spins_$todayKey', spins);
        print('🎰 SPIN: Guest spin count updated in SharedPreferences');
      } catch (e) {
        print('❌ SPIN ERROR: Failed to increment guest spins: $e');
        throw e;
      }
      return;
    }

    try {
      final todayKey = _dateKey(DateTime.now());
      print('🎰 SPIN: Incrementing spins for date: $todayKey, user: $_userId');

      final spinDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('spins')
          .doc(todayKey)
          .get();

      int spins = spinDoc.data()?['count'] ?? 0;
      print('🎰 SPIN: Current spins: $spins');

      spins += 1;
      print('🎰 SPIN: New spins count: $spins');

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('spins')
          .doc(todayKey)
          .set({'count': spins});

      print('🎰 SPIN: Spin count updated in Firestore');
    } catch (e) {
      print('❌ SPIN ERROR: Failed to increment spins today: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  /// Reset spins if a new day has started (optional, for cleanup)
  static Future<void> resetSpinsIfNewDay() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && isGuest) {
      // Guest user - check if we need to reset for new day
      print('🎰 SPIN: Guest user - checking for new day reset');
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastSpinDate = prefs.getString('last_spin_date');
        final todayKey = _dateKey(DateTime.now());

        if (lastSpinDate != todayKey) {
          // New day, reset spins
          await prefs.setString('last_spin_date', todayKey);
          await prefs.remove('spins_$todayKey');
          print('🎰 SPIN: Guest spins reset for new day');
        }
      } catch (e) {
        print('❌ SPIN ERROR: Failed to reset guest spins: $e');
      }
      return;
    }

    // This is handled automatically by Firestore's document structure
    // Old spin documents can be cleaned up periodically if needed
  }

  /// Clear today's challenge (for reset functionality)
  static Future<void> clearTodaysChallenge() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) {
      print('🎯 CHALLENGE: No user ID available for clearing challenge');
      return;
    }

    try {
      final todayKey = _dateKey(DateTime.now());
      print('🎯 CHALLENGE: Clearing today\'s challenge for date: $todayKey');

      if (isGuest) {
        // Guest user - clear from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('guest_challenge_$todayKey');
        print('✅ CHALLENGE: Guest challenge cleared successfully');
      } else {
        // Firebase user - clear from Firestore
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('challenges')
            .doc(todayKey)
            .delete();
        print('✅ CHALLENGE: Today\'s challenge cleared successfully');
      }
    } catch (e) {
      print('❌ CHALLENGE ERROR: Failed to clear today\'s challenge: $e');
      throw e;
    }
  }

  /// Utility: format date as yyyy-MM-dd
  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
