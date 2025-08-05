import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';

class ModifierService {
  static List<Modifier> _modifiers = [];
  static List<Map<String, dynamic>> _categories = [];
  static List<Map<String, dynamic>> _challenges = [];
  static bool _initialized = false;

  /// Initialize modifiers from JSON
  static Future<void> initialize() async {
    if (_initialized) return;

    print('🎯 MODIFIER: Initializing modifiers...');
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/challenge_bank.json',
      );
      final jsonData = json.decode(jsonString);

      _modifiers = (jsonData['modifiers'] as List)
          .map((modifier) => Modifier.fromMap(modifier))
          .toList();

      _categories = List<Map<String, dynamic>>.from(
        jsonData['categories'] ?? [],
      );
      _challenges = List<Map<String, dynamic>>.from(
        jsonData['challenges'] ?? [],
      );

      print(
        '🎯 MODIFIER: Loaded ${_modifiers.length} modifiers, ${_categories.length} categories, ${_challenges.length} challenges',
      );
      _initialized = true;
    } catch (e) {
      print('❌ MODIFIER ERROR: Failed to load modifiers: $e');
    }
  }

  /// Get all available modifiers
  static List<Modifier> getAllModifiers() {
    if (!_initialized) {
      print('⚠️ MODIFIER: Not initialized, calling initialize()');
      initialize();
    }
    return _modifiers;
  }

  /// Get all categories
  static List<Map<String, dynamic>> getAllCategories() {
    if (!_initialized) {
      print('⚠️ MODIFIER: Not initialized, calling initialize()');
      initialize();
    }
    return _categories;
  }

  /// Get all challenges
  static List<Map<String, dynamic>> getAllChallenges() {
    if (!_initialized) {
      print('⚠️ MODIFIER: Not initialized, calling initialize()');
      initialize();
    }
    return _challenges;
  }

  /// Get challenges by category
  static List<Map<String, dynamic>> getChallengesByCategory(String categoryId) {
    return _challenges
        .where((challenge) => challenge['category'] == categoryId)
        .toList();
  }

  /// Get random challenge from a specific category
  static Map<String, dynamic>? getRandomChallengeFromCategory(
    String categoryId,
  ) {
    final categoryChallenges = getChallengesByCategory(categoryId);
    if (categoryChallenges.isEmpty) return null;

    final random = Random();
    return categoryChallenges[random.nextInt(categoryChallenges.length)];
  }

  /// Get modifiers for a specific challenge
  static List<String> getModifiersForChallenge(String challengeId) {
    final challenge = _challenges.firstWhere(
      (c) => c['id'] == challengeId,
      orElse: () => <String, dynamic>{},
    );

    return List<String>.from(challenge['modifiers'] ?? []);
  }

  /// Get modifiers by category
  static List<Modifier> getModifiersByCategory(String category) {
    return _modifiers.where((modifier) {
      switch (category) {
        case 'fun':
          return [
            'chopsticks',
            'blindfolded',
            'one_hand',
            'non_dominant',
            'balance',
            'dance',
            'sing',
          ].contains(modifier.id);
        case 'mindful':
          return ['count', 'slow', 'silent', 'grateful'].contains(modifier.id);
        case 'social':
          return ['share', 'teach', 'new_location'].contains(modifier.id);
        case 'creative':
          return ['creative', 'colorful', 'minimal'].contains(modifier.id);
        case 'healthy':
          return ['healthy'].contains(modifier.id);
        case 'adventure':
          return ['cultural'].contains(modifier.id);
        default:
          return true;
      }
    }).toList();
  }

  /// Get random modifiers (1-3 as per PRD)
  static List<Modifier> getRandomModifiers({int count = 3}) {
    if (_modifiers.isEmpty) return [];

    final shuffled = List<Modifier>.from(_modifiers)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Calculate total points for modifiers
  static int calculateModifierPoints(List<String> modifierIds) {
    int totalPoints = 0;
    for (final id in modifierIds) {
      final modifier = _modifiers.firstWhere(
        (m) => m.id == id,
        orElse: () => Modifier(id: '', text: '', points: 0, icon: ''),
      );
      totalPoints += modifier.points;
    }
    return totalPoints;
  }

  /// Get modifier by ID
  static Modifier? getModifierById(String id) {
    try {
      return _modifiers.firstWhere((modifier) => modifier.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get popular modifiers (most used)
  static List<Modifier> getPopularModifiers({int count = 5}) {
    // For now, return random modifiers. In the future, this could be based on usage data
    return getRandomModifiers(count: count);
  }
}
