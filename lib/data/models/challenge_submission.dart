import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'challenge_submission.g.dart';

@HiveType(typeId: 200)
@JsonSerializable()
class ChallengeSubmission {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String challengeId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String userName;
  @HiveField(4)
  @JsonKey(name: 'type_id')
  final int typeId; // This should be unique across all submissions
  @HiveField(5)
  final String submissionTitle;
  @HiveField(6)
  final String submissionDescription;
  @HiveField(7)
  final String? imageUrl;
  @HiveField(8)
  final String? videoUrl;
  @HiveField(9)
  final List<String> tags;
  @HiveField(10)
  final DateTime submittedAt;
  @HiveField(11)
  final DateTime? updatedAt;
  @HiveField(12)
  final SubmissionStatus status;
  @HiveField(13)
  final int likesCount;
  @HiveField(14)
  final int commentsCount;
  @HiveField(15)
  final List<String> likedBy;
  @HiveField(16)
  final Map<String, dynamic>? metadata;

  const ChallengeSubmission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.typeId,
    required this.submissionTitle,
    required this.submissionDescription,
    this.imageUrl,
    this.videoUrl,
    required this.tags,
    required this.submittedAt,
    this.updatedAt,
    required this.status,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.metadata,
  });

  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeSubmissionToJson(this);

  ChallengeSubmission copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    int? typeId,
    String? submissionTitle,
    String? submissionDescription,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
    DateTime? submittedAt,
    DateTime? updatedAt,
    SubmissionStatus? status,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeSubmission(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      typeId: typeId ?? this.typeId,
      submissionTitle: submissionTitle ?? this.submissionTitle,
      submissionDescription:
          submissionDescription ?? this.submissionDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      tags: tags ?? this.tags,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeSubmission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChallengeSubmission(id: $id, challengeId: $challengeId, userId: $userId, typeId: $typeId, submissionTitle: $submissionTitle)';
  }
}

enum SubmissionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('under_review')
  underReview,
}

extension SubmissionStatusExtension on SubmissionStatus {
  String get displayName {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Pending';
      case SubmissionStatus.approved:
        return 'Approved';
      case SubmissionStatus.rejected:
        return 'Rejected';
      case SubmissionStatus.underReview:
        return 'Under Review';
    }
  }

  bool get isApproved => this == SubmissionStatus.approved;
  bool get isRejected => this == SubmissionStatus.rejected;
  bool get isPending => this == SubmissionStatus.pending;
  bool get isUnderReview => this == SubmissionStatus.underReview;
}
