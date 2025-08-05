import 'package:flutter_test/flutter_test.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';

void main() {
  group('ChallengeSubmission Model Tests', () {
    test('should create a valid ChallengeSubmission', () {
      final submission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        tags: ['healthy', 'quick'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.pending,
        likesCount: 5,
        commentsCount: 2,
        likedBy: ['user1', 'user2'],
      );

      expect(submission.id, equals('submission_id'));
      expect(submission.challengeId, equals('challenge_id'));
      expect(submission.userId, equals('user_id'));
      expect(submission.userName, equals('Test User'));
      expect(submission.typeId, equals(1));
      expect(submission.submissionTitle, equals('Test Submission'));
      expect(submission.submissionDescription, equals('Test Description'));
      expect(submission.imageUrl, equals('https://example.com/image.jpg'));
      expect(submission.tags, containsAll(['healthy', 'quick']));
      expect(submission.status, equals(SubmissionStatus.pending));
      expect(submission.likesCount, equals(5));
      expect(submission.commentsCount, equals(2));
      expect(submission.likedBy, containsAll(['user1', 'user2']));
    });

    test('should convert ChallengeSubmission to JSON and back', () {
      final originalSubmission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        imageUrl: 'https://example.com/image.jpg',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.approved,
        likesCount: 3,
        commentsCount: 1,
        likedBy: ['user1'],
      );

      final json = originalSubmission.toJson();
      final restoredSubmission = ChallengeSubmission.fromJson(json);

      expect(restoredSubmission.id, equals(originalSubmission.id));
      expect(
        restoredSubmission.challengeId,
        equals(originalSubmission.challengeId),
      );
      expect(restoredSubmission.userId, equals(originalSubmission.userId));
      expect(restoredSubmission.userName, equals(originalSubmission.userName));
      expect(restoredSubmission.typeId, equals(originalSubmission.typeId));
      expect(
        restoredSubmission.submissionTitle,
        equals(originalSubmission.submissionTitle),
      );
      expect(
        restoredSubmission.submissionDescription,
        equals(originalSubmission.submissionDescription),
      );
      expect(restoredSubmission.imageUrl, equals(originalSubmission.imageUrl));
      expect(restoredSubmission.tags, equals(originalSubmission.tags));
      expect(restoredSubmission.status, equals(originalSubmission.status));
      expect(
        restoredSubmission.likesCount,
        equals(originalSubmission.likesCount),
      );
      expect(
        restoredSubmission.commentsCount,
        equals(originalSubmission.commentsCount),
      );
      expect(restoredSubmission.likedBy, equals(originalSubmission.likedBy));
    });

    test('should handle optional fields', () {
      final submission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.pending,
      );

      expect(submission.imageUrl, isNull);
      expect(submission.videoUrl, isNull);
      expect(submission.updatedAt, isNull);
      expect(submission.metadata, isNull);
      expect(submission.likesCount, equals(0));
      expect(submission.commentsCount, equals(0));
      expect(submission.likedBy, isEmpty);
    });

    test('should create copy with updated values', () {
      final originalSubmission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.pending,
      );

      final updatedSubmission = originalSubmission.copyWith(
        submissionTitle: 'Updated Title',
        status: SubmissionStatus.approved,
        likesCount: 10,
      );

      expect(updatedSubmission.id, equals(originalSubmission.id));
      expect(updatedSubmission.submissionTitle, equals('Updated Title'));
      expect(updatedSubmission.status, equals(SubmissionStatus.approved));
      expect(updatedSubmission.likesCount, equals(10));
      expect(
        updatedSubmission.submissionDescription,
        equals(originalSubmission.submissionDescription),
      );
    });

    test('should handle different submission statuses', () {
      final pendingSubmission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.pending,
      );

      final approvedSubmission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.approved,
      );

      final rejectedSubmission = ChallengeSubmission(
        id: 'submission_id',
        challengeId: 'challenge_id',
        userId: 'user_id',
        userName: 'Test User',
        typeId: 1,
        submissionTitle: 'Test Submission',
        submissionDescription: 'Test Description',
        tags: ['healthy'],
        submittedAt: DateTime(2024, 1, 1),
        status: SubmissionStatus.rejected,
      );

      expect(pendingSubmission.status, equals(SubmissionStatus.pending));
      expect(approvedSubmission.status, equals(SubmissionStatus.approved));
      expect(rejectedSubmission.status, equals(SubmissionStatus.rejected));
    });
  });
}
