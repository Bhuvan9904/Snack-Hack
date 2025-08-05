import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';

class BadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Check if current user is a guest
  static Future<bool> _isGuestUser() async {
    return _userId == null && await GuestUserService.isGuestSessionValid();
  }

  // List of all badge IDs
  static const String firstSpin = 'first_spin';
  static const String healthySnack = 'healthy_snack';
  static const String streak3 = 'streak_3';
  static const String proof5 = 'proof_5';
  static const String challenge10 = 'challenge_10';

  // New creative badges
  static const String rainbowChewer = 'rainbow_chewer';
  static const String minimalistMaster = 'minimalist_master';
  static const String modifierMaster = 'modifier_master';
  static const String chopstickPro = 'chopstick_pro';
  static const String blindfoldedBrave = 'blindfolded_brave';
  static const String balanceMaster = 'balance_master';
  static const String culturalExplorer = 'cultural_explorer';
  static const String socialButterfly = 'social_butterfly';
  static const String mindfulEater = 'mindful_eater';
  static const String creativeChef = 'creative_chef';

  static Future<List<String>> getEarnedBadges() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return [];

    if (isGuest) {
      // Guest users don't have badges yet
      print('🏆 BADGE: Guest user - no badges available');
      return [];
    }

    final doc = await _firestore.collection('users').doc(_userId).get();
    final userData = doc.data();
    final badges = List<String>.from(userData?['earnedBadges'] ?? []);
    print('DEBUG: getEarnedBadges called, badges=$badges');
    return badges;
  }

  static Future<void> _saveEarnedBadges(List<String> badges) async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return;

    if (isGuest) {
      // Guest users can't save badges to Firestore
      print(
        '🏆 BADGE: Guest user - badges not saved (will be saved when account created)',
      );
      return;
    }

    print('DEBUG: Writing badges to Firestore: $badges');
    await _firestore.collection('users').doc(_userId).update({
      'earnedBadges': badges,
    });
  }

  static Future<void> checkAndAwardBadges({
    required int totalSpins,
    required int streak,
    required int proofCount,
    required int completedChallenges,
    required bool healthySnackSubmitted,
    int modifierPoints = 0,
    int modifiersUsed = 0,
    List<String> modifierIds = const [],
  }) async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) {
      print('❌ BADGE: No user ID available for badge check');
      return;
    }

    if (isGuest) {
      // Guest users can't earn badges yet
      print(
        '🏆 BADGE: Guest user - badges will be awarded when account is created',
      );
      return;
    }

    print('🏆 BADGE: Checking for new badges...');
    print('   - Total spins: $totalSpins');
    print('   - Current streak: $streak');
    print('   - Proof count: $proofCount');
    print('   - Completed challenges: $completedChallenges');
    print('   - Healthy snack submitted: $healthySnackSubmitted');
    print('   - Modifier points: $modifierPoints');
    print('   - Modifiers used: $modifiersUsed');
    print('   - Modifier IDs: $modifierIds');

    final badges = await getEarnedBadges();
    print('🏆 BADGE: Current badges: $badges');
    bool updated = false;

    // Basic badges
    if (totalSpins >= 1 && !badges.contains(firstSpin)) {
      print('🏆 BADGE: Awarding First Spin badge!');
      badges.add(firstSpin);
      updated = true;
    }
    if (healthySnackSubmitted && !badges.contains(healthySnack)) {
      print('🏆 BADGE: Awarding Healthy Snack badge!');
      badges.add(healthySnack);
      updated = true;
    }
    if (streak >= 3 && !badges.contains(streak3)) {
      print('🏆 BADGE: Awarding Streak 3+ badge!');
      badges.add(streak3);
      updated = true;
    }
    if (proofCount >= 5 && !badges.contains(proof5)) {
      print('🏆 BADGE: Awarding Proof Master badge!');
      badges.add(proof5);
      updated = true;
    }
    if (completedChallenges >= 10 && !badges.contains(challenge10)) {
      print('🏆 BADGE: Awarding Snack Pro badge!');
      badges.add(challenge10);
      updated = true;
    }

    // Modifier-related badges
    if (modifiersUsed >= 5 && !badges.contains(modifierMaster)) {
      print('🏆 BADGE: Awarding Modifier Master badge!');
      badges.add(modifierMaster);
      updated = true;
    }

    // Specific modifier badges
    if (modifierIds.contains('chopsticks') && !badges.contains(chopstickPro)) {
      print('🏆 BADGE: Awarding Chopstick Pro badge!');
      badges.add(chopstickPro);
      updated = true;
    }
    if (modifierIds.contains('blindfolded') &&
        !badges.contains(blindfoldedBrave)) {
      print('🏆 BADGE: Awarding Blindfolded Brave badge!');
      badges.add(blindfoldedBrave);
      updated = true;
    }
    if (modifierIds.contains('balance') && !badges.contains(balanceMaster)) {
      print('🏆 BADGE: Awarding Balance Master badge!');
      badges.add(balanceMaster);
      updated = true;
    }
    if (modifierIds.contains('cultural') &&
        !badges.contains(culturalExplorer)) {
      print('🏆 BADGE: Awarding Cultural Explorer badge!');
      badges.add(culturalExplorer);
      updated = true;
    }
    if (modifierIds.contains('share') && !badges.contains(socialButterfly)) {
      print('🏆 BADGE: Awarding Social Butterfly badge!');
      badges.add(socialButterfly);
      updated = true;
    }
    if (modifierIds.contains('silent') && !badges.contains(mindfulEater)) {
      print('🏆 BADGE: Awarding Mindful Eater badge!');
      badges.add(mindfulEater);
      updated = true;
    }
    if (modifierIds.contains('creative') && !badges.contains(creativeChef)) {
      print('🏆 BADGE: Awarding Creative Chef badge!');
      badges.add(creativeChef);
      updated = true;
    }

    if (updated) {
      print('🏆 BADGE: Saving updated badges: $badges');
      await _saveEarnedBadges(badges);
    } else {
      print('🏆 BADGE: No new badges to award');
    }
  }

  static Future<bool> hasBadge(String badgeId) async {
    final badges = await getEarnedBadges();
    return badges.contains(badgeId);
  }

  // Get badge display information
  static Map<String, Map<String, dynamic>> getBadgeInfo() {
    return {
      firstSpin: {
        'name': 'First Spin',
        'description': 'Completed your first spin!',
        'icon': '🎯',
        'color': 0xFF4CAF50,
      },
      healthySnack: {
        'name': 'Healthy Bite',
        'description': 'Submitted a healthy snack',
        'icon': '🥗',
        'color': 0xFF8BC34A,
      },
      streak3: {
        'name': 'Streak Master',
        'description': 'Maintained a 3+ day streak',
        'icon': '🔥',
        'color': 0xFFFF9800,
      },
      proof5: {
        'name': 'Proof Master',
        'description': 'Submitted 5+ challenge proofs',
        'icon': '📸',
        'color': 0xFF2196F3,
      },
      challenge10: {
        'name': 'Snack Pro',
        'description': 'Completed 10+ challenges',
        'icon': '🏆',
        'color': 0xFF9C27B0,
      },
      modifierMaster: {
        'name': 'Modifier Master',
        'description': 'Used 5+ modifiers in challenges',
        'icon': '⭐',
        'color': 0xFFFFD700,
      },
      chopstickPro: {
        'name': 'Chopstick Pro',
        'description': 'Mastered eating with chopsticks',
        'icon': '🥢',
        'color': 0xFF795548,
      },
      blindfoldedBrave: {
        'name': 'Blindfolded Brave',
        'description': 'Ate a snack blindfolded',
        'icon': '👁️',
        'color': 0xFF607D8B,
      },
      balanceMaster: {
        'name': 'Balance Master',
        'description': 'Ate while standing on one leg',
        'icon': '🦵',
        'color': 0xFFE91E63,
      },
      culturalExplorer: {
        'name': 'Cultural Explorer',
        'description': 'Tried food from different cultures',
        'icon': '🌍',
        'color': 0xFF3F51B5,
      },
      socialButterfly: {
        'name': 'Social Butterfly',
        'description': 'Shared snacks with others',
        'icon': '🤝',
        'color': 0xFF00BCD4,
      },
      mindfulEater: {
        'name': 'Mindful Eater',
        'description': 'Ate in complete silence',
        'icon': '🤫',
        'color': 0xFF673AB7,
      },
      creativeChef: {
        'name': 'Creative Chef',
        'description': 'Made artistic food arrangements',
        'icon': '🎨',
        'color': 0xFFFF5722,
      },
    };
  }
}
