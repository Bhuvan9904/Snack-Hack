class Group {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final List<String> admins;
  final String inviteCode;
  final bool isPrivate;
  final int maxMembers;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.admins,
    required this.inviteCode,
    this.isPrivate = false,
    this.maxMembers = 20,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'members': members,
    'admins': admins,
    'inviteCode': inviteCode,
    'isPrivate': isPrivate,
    'maxMembers': maxMembers,
  };

  static Group fromMap(Map<String, dynamic> map) => Group(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    createdBy: map['createdBy'],
    createdAt: DateTime.parse(map['createdAt']),
    members: List<String>.from(map['members']),
    admins: List<String>.from(map['admins']),
    inviteCode: map['inviteCode'],
    isPrivate: map['isPrivate'] ?? false,
    maxMembers: map['maxMembers'] ?? 20,
  );

  bool get isFull => members.length >= maxMembers;
  bool get canJoin => !isFull;
  bool isMember(String userId) => members.contains(userId);
  bool isAdmin(String userId) => admins.contains(userId) || createdBy == userId;
}

class GroupSubmission {
  final String id;
  final String groupId;
  final String userId;
  final String challengeId;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> modifiers;
  final DateTime submittedAt;
  final Map<String, String>
  votes; // userId -> vote type ("nailed_it" or "close_try")

  GroupSubmission({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.challengeId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.modifiers,
    required this.submittedAt,
    required this.votes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'userId': userId,
    'challengeId': challengeId,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'modifiers': modifiers,
    'submittedAt': submittedAt.toIso8601String(),
    'votes': votes,
  };

  static GroupSubmission fromMap(Map<String, dynamic> map) => GroupSubmission(
    id: map['id'],
    groupId: map['groupId'],
    userId: map['userId'],
    challengeId: map['challengeId'],
    title: map['title'],
    description: map['description'],
    imageUrl: map['imageUrl'],
    modifiers: List<String>.from(map['modifiers']),
    submittedAt: DateTime.parse(map['submittedAt']),
    votes: Map<String, String>.from(map['votes']),
  );

  int get nailedItVotes =>
      votes.values.where((vote) => vote == 'nailed_it').length;
  int get closeTryVotes =>
      votes.values.where((vote) => vote == 'close_try').length;
  int get totalVotes => votes.length;
  bool hasUserVoted(String userId) => votes.containsKey(userId);

  GroupSubmission copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? challengeId,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? modifiers,
    DateTime? submittedAt,
    Map<String, String>? votes,
  }) {
    return GroupSubmission(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      modifiers: modifiers ?? this.modifiers,
      submittedAt: submittedAt ?? this.submittedAt,
      votes: votes ?? this.votes,
    );
  }
}
