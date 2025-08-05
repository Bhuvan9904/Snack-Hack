// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_submission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeSubmissionAdapter extends TypeAdapter<ChallengeSubmission> {
  @override
  final int typeId = 200;

  @override
  ChallengeSubmission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeSubmission(
      id: fields[0] as String,
      challengeId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      typeId: fields[4] as int,
      submissionTitle: fields[5] as String,
      submissionDescription: fields[6] as String,
      imageUrl: fields[7] as String?,
      videoUrl: fields[8] as String?,
      tags: (fields[9] as List).cast<String>(),
      submittedAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime?,
      status: fields[12] as SubmissionStatus,
      likesCount: fields[13] as int,
      commentsCount: fields[14] as int,
      likedBy: (fields[15] as List).cast<String>(),
      metadata: (fields[16] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeSubmission obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.challengeId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.typeId)
      ..writeByte(5)
      ..write(obj.submissionTitle)
      ..writeByte(6)
      ..write(obj.submissionDescription)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.videoUrl)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.submittedAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.likesCount)
      ..writeByte(14)
      ..write(obj.commentsCount)
      ..writeByte(15)
      ..write(obj.likedBy)
      ..writeByte(16)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeSubmissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeSubmission _$ChallengeSubmissionFromJson(Map<String, dynamic> json) =>
    ChallengeSubmission(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      typeId: (json['type_id'] as num).toInt(),
      submissionTitle: json['submissionTitle'] as String,
      submissionDescription: json['submissionDescription'] as String,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      status: $enumDecode(_$SubmissionStatusEnumMap, json['status']),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChallengeSubmissionToJson(
        ChallengeSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'challengeId': instance.challengeId,
      'userId': instance.userId,
      'userName': instance.userName,
      'type_id': instance.typeId,
      'submissionTitle': instance.submissionTitle,
      'submissionDescription': instance.submissionDescription,
      'imageUrl': instance.imageUrl,
      'videoUrl': instance.videoUrl,
      'tags': instance.tags,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'status': _$SubmissionStatusEnumMap[instance.status]!,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'likedBy': instance.likedBy,
      'metadata': instance.metadata,
    };

const _$SubmissionStatusEnumMap = {
  SubmissionStatus.pending: 'pending',
  SubmissionStatus.approved: 'approved',
  SubmissionStatus.rejected: 'rejected',
  SubmissionStatus.underReview: 'under_review',
};
