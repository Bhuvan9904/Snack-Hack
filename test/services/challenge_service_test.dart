import 'package:flutter_test/flutter_test.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';

void main() {
  group('ChallengeService Tests', () {
    test('should create a valid ChallengeEntry', () {
      final challenge = ChallengeEntry(
        challengeText: 'Test Challenge',
        date: DateTime.now(),
        modifiers: ['modifier1', 'modifier2'],
        completed: false,
        category: 'test_category',
        difficulty: 'easy',
        id: 'test_id',
      );

      expect(challenge.challengeText, equals('Test Challenge'));
      expect(challenge.modifiers, containsAll(['modifier1', 'modifier2']));
      expect(challenge.completed, isFalse);
      expect(challenge.category, equals('test_category'));
      expect(challenge.difficulty, equals('easy'));
      expect(challenge.id, equals('test_id'));
    });

    test('should convert ChallengeEntry to map and back', () {
      final originalChallenge = ChallengeEntry(
        challengeText: 'Test Challenge',
        date: DateTime(2024, 1, 1),
        modifiers: ['modifier1'],
        completed: true,
        category: 'test_category',
        difficulty: 'medium',
        id: 'test_id',
      );

      final map = originalChallenge.toMap();
      final restoredChallenge = ChallengeEntry.fromMap(map);

      expect(
        restoredChallenge.challengeText,
        equals(originalChallenge.challengeText),
      );
      expect(restoredChallenge.modifiers, equals(originalChallenge.modifiers));
      expect(restoredChallenge.completed, equals(originalChallenge.completed));
      expect(restoredChallenge.category, equals(originalChallenge.category));
      expect(
        restoredChallenge.difficulty,
        equals(originalChallenge.difficulty),
      );
      expect(restoredChallenge.id, equals(originalChallenge.id));
    });

    test('should handle empty modifiers list', () {
      final challenge = ChallengeEntry(
        challengeText: 'Test Challenge',
        date: DateTime.now(),
        modifiers: [],
        completed: false,
        category: 'test_category',
        difficulty: 'easy',
        id: 'test_id',
      );

      expect(challenge.modifiers, isEmpty);
    });

    test('should handle null values in map conversion', () {
      final map = {
        'challengeText': 'Test Challenge',
        'date': DateTime.now().toIso8601String(),
        'modifiers': ['modifier1'],
        'completed': false,
        'category': 'test_category',
        'difficulty': 'easy',
        'id': 'test_id',
      };

      final challenge = ChallengeEntry.fromMap(map);
      expect(challenge.challengeText, equals('Test Challenge'));
    });
  });
}
