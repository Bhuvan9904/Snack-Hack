import 'package:flutter_test/flutter_test.dart';
import 'package:snack_hack_app/data/models/group_model.dart';

void main() {
  group('GroupSubmission Model Tests', () {
    test('should create a valid GroupSubmission', () {
      final submission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1', 'modifier2'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {'user1': 'nailed_it', 'user2': 'close_try'},
      );

      expect(submission.id, equals('submission_id'));
      expect(submission.groupId, equals('group_id'));
      expect(submission.userId, equals('user_id'));
      expect(submission.challengeId, equals('challenge_id'));
      expect(submission.title, equals('Test Submission'));
      expect(submission.description, equals('Test Description'));
      expect(submission.imageUrl, equals('https://example.com/image.jpg'));
      expect(submission.modifiers, containsAll(['modifier1', 'modifier2']));
      expect(submission.votes, containsPair('user1', 'nailed_it'));
    });

    test('should convert GroupSubmission to map and back', () {
      final originalSubmission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {'user1': 'nailed_it'},
      );

      final map = originalSubmission.toMap();
      final restoredSubmission = GroupSubmission.fromMap(map);

      expect(restoredSubmission.id, equals(originalSubmission.id));
      expect(restoredSubmission.groupId, equals(originalSubmission.groupId));
      expect(restoredSubmission.userId, equals(originalSubmission.userId));
      expect(
        restoredSubmission.challengeId,
        equals(originalSubmission.challengeId),
      );
      expect(restoredSubmission.title, equals(originalSubmission.title));
      expect(
        restoredSubmission.description,
        equals(originalSubmission.description),
      );
      expect(restoredSubmission.imageUrl, equals(originalSubmission.imageUrl));
      expect(
        restoredSubmission.modifiers,
        equals(originalSubmission.modifiers),
      );
      expect(restoredSubmission.votes, equals(originalSubmission.votes));
    });

    test('should calculate vote counts correctly', () {
      final submission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {
          'user1': 'nailed_it',
          'user2': 'nailed_it',
          'user3': 'close_try',
          'user4': 'close_try',
          'user5': 'close_try',
        },
      );

      expect(submission.nailedItVotes, equals(2));
      expect(submission.closeTryVotes, equals(3));
      expect(submission.totalVotes, equals(5));
    });

    test('should check if user has voted', () {
      final submission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {'user1': 'nailed_it', 'user2': 'close_try'},
      );

      expect(submission.hasUserVoted('user1'), isTrue);
      expect(submission.hasUserVoted('user2'), isTrue);
      expect(submission.hasUserVoted('user3'), isFalse);
    });

    test('should handle empty votes', () {
      final submission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {},
      );

      expect(submission.nailedItVotes, equals(0));
      expect(submission.closeTryVotes, equals(0));
      expect(submission.totalVotes, equals(0));
    });

    test('should create copy with updated values', () {
      final originalSubmission = GroupSubmission(
        id: 'submission_id',
        groupId: 'group_id',
        userId: 'user_id',
        challengeId: 'challenge_id',
        title: 'Test Submission',
        description: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        modifiers: ['modifier1'],
        submittedAt: DateTime(2024, 1, 1),
        votes: {'user1': 'nailed_it'},
      );

      final updatedSubmission = originalSubmission.copyWith(
        title: 'Updated Title',
        votes: {'user1': 'nailed_it', 'user2': 'close_try'},
      );

      expect(updatedSubmission.id, equals(originalSubmission.id));
      expect(updatedSubmission.title, equals('Updated Title'));
      expect(updatedSubmission.votes, containsPair('user2', 'close_try'));
      expect(
        updatedSubmission.description,
        equals(originalSubmission.description),
      );
    });
  });
}
