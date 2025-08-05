import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/data/models/group_model.dart';

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Create a new group
  static Future<Group> createGroup({
    required String name,
    required String description,
    bool isPrivate = false,
    int maxMembers = 20,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('👥 GROUP: Creating new group: $name');

    final group = Group(
      id: _firestore.collection('groups').doc().id,
      name: name,
      description: description,
      createdBy: _userId!,
      createdAt: DateTime.now(),
      members: [_userId!],
      admins: [_userId!],
      inviteCode: '', // Empty string since we're not using invite codes
      isPrivate: isPrivate,
      maxMembers: maxMembers,
    );

    await _firestore.collection('groups').doc(group.id).set(group.toMap());

    print('✅ GROUP: Group created successfully');
    return group;
  }

  /// Get user's groups
  static Future<List<Group>> getUserGroups() async {
    if (_userId == null) return [];

    print('👥 GROUP: Fetching user groups...');
    print('👥 GROUP: Current user ID: $_userId');

    final querySnapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: _userId)
        .get();

    print('👥 GROUP: Query returned ${querySnapshot.docs.length} documents');

    final groups = querySnapshot.docs.map((doc) {
      print('👥 GROUP: Processing group document: ${doc.id}');
      print('👥 GROUP: Group data: ${doc.data()}');
      final data = doc.data();
      // Use the Firestore document ID instead of the stored ID
      data['id'] = doc.id;
      return Group.fromMap(data);
    }).toList();

    print('👥 GROUP: Found ${groups.length} groups');
    for (final group in groups) {
      print('👥 GROUP: Group: ${group.name} (ID: ${group.id})');
    }
    return groups;
  }

  /// Submit a challenge to a group
  static Future<void> submitToGroup(GroupSubmission submission) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('📸 GROUP: Submitting challenge to group: ${submission.groupId}');

    await _firestore
        .collection('groups')
        .doc(submission.groupId)
        .collection('submissions')
        .doc(submission.id)
        .set(submission.toMap());

    print('✅ GROUP: Challenge submitted successfully');
  }

  /// Get group submissions
  static Future<List<GroupSubmission>> getGroupSubmissions(
    String groupId,
  ) async {
    print('📸 GROUP: Fetching submissions for group: $groupId');

    final querySnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .get();

    final submissions = querySnapshot.docs
        .map((doc) => GroupSubmission.fromMap(doc.data()))
        .toList();

    print('📸 GROUP: Found ${submissions.length} submissions');
    return submissions;
  }

  /// Vote on a submission
  static Future<void> voteOnSubmission({
    required String submissionId,
    required String groupId,
    required String voteType, // 'nailed_it' or 'close_try'
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('🗳️ VOTE: Voting $voteType on submission: $submissionId');

    try {
      // Get the submission from the correct location: groups/{groupId}/submissions/{submissionId}
      final submissionRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('submissions')
          .doc(submissionId);

      final submissionDoc = await submissionRef.get();
      if (!submissionDoc.exists) throw Exception('Submission not found');

      final submission = GroupSubmission.fromMap(submissionDoc.data()!);

      // Check if user is a member of the group
      if (submission.groupId != groupId) {
        throw Exception('You can only vote on submissions in your groups');
      }

      // Update the votes
      final updatedVotes = Map<String, String>.from(submission.votes);
      updatedVotes[_userId!] = voteType;

      await submissionRef.update({'votes': updatedVotes});

      // Award points to the submission owner based on vote type
      if (voteType == 'nailed_it') {
        // +5 points for "Nailed it" vote
        await _awardPointsToUser(submission.userId, 5);
      } else if (voteType == 'close_try') {
        // +1 point for "Close try" vote
        await _awardPointsToUser(submission.userId, 1);
      }

      print('✅ VOTE: Vote recorded successfully');
    } catch (e) {
      print('❌ VOTE ERROR: $e');
      throw Exception('Failed to vote: $e');
    }
  }

  /// Award points to a user
  static Future<void> _awardPointsToUser(String userId, int points) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentPoints = userDoc.data()!['points'] ?? 0;
        await _firestore.collection('users').doc(userId).update({
          'points': currentPoints + points,
        });
        print('🎯 GROUP: Awarded $points points to user $userId');
      }
    } catch (e) {
      print('❌ GROUP ERROR: Failed to award points: $e');
    }
  }

  /// Get group leaderboard
  static Future<List<Map<String, dynamic>>> getGroupLeaderboard(
    String groupId,
  ) async {
    print('🏆 LEADERBOARD: Fetching leaderboard for group: $groupId');

    final submissions = await getGroupSubmissions(groupId);
    final Map<String, int> userPoints = {};

    for (final submission in submissions) {
      final points =
          submission.nailedItVotes * 5 + submission.closeTryVotes * 1;
      userPoints[submission.userId] =
          (userPoints[submission.userId] ?? 0) + points;
    }

    final leaderboard =
        userPoints.entries
            .map((entry) => {'userId': entry.key, 'points': entry.value})
            .toList()
          ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    print(
      '🏆 LEADERBOARD: Generated leaderboard with ${leaderboard.length} users',
    );
    return leaderboard;
  }

  /// Delete a group (only for admins)
  static Future<void> deleteGroup(String groupId) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('🗑️ GROUP: Deleting group: $groupId');

    try {
      // First, get the group to check if user is admin
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupDoc.data()!);

      if (!group.isAdmin(_userId!)) {
        throw Exception('Only group admins can delete groups');
      }

      // Delete all group submissions
      final submissionsQuery = await _firestore
          .collection('groupSubmissions')
          .where('groupId', isEqualTo: groupId)
          .get();

      final batch = _firestore.batch();

      // Delete group submissions
      for (final doc in submissionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the group itself
      batch.delete(groupDoc.reference);

      // Commit the batch
      await batch.commit();

      print('✅ GROUP: Group deleted successfully');
    } catch (e) {
      print('❌ GROUP ERROR: $e');
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Leave a group (for members)
  static Future<void> leaveGroup(String groupId) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('🚪 GROUP: User leaving group: $groupId');

    try {
      // First, get the group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = Group.fromMap(groupDoc.data()!);

      if (!group.isMember(_userId!)) {
        throw Exception('You are not a member of this group');
      }

      // Check if user is the only admin (can't leave if they're the only admin)
      if (group.isAdmin(_userId!) && group.admins.length == 1) {
        throw Exception(
          'Cannot leave group: You are the only admin. Please delete the group or transfer admin rights first.',
        );
      }

      // Remove user from members list
      final updatedMembers = List<String>.from(group.members)..remove(_userId!);

      // Remove user from admins list if they are an admin
      final updatedAdmins = List<String>.from(group.admins);
      if (group.isAdmin(_userId!)) {
        updatedAdmins.remove(_userId!);
      }

      // Update the group
      await _firestore.collection('groups').doc(groupId).update({
        'members': updatedMembers,
        'admins': updatedAdmins,
      });

      print('✅ GROUP: User left group successfully');
    } catch (e) {
      print('❌ GROUP ERROR: $e');
      throw Exception('Failed to leave group: $e');
    }
  }
}

// Extension to add copyWith method to Group
extension GroupCopyWith on Group {
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? members,
    List<String>? admins,
    String? inviteCode,
    bool? isPrivate,
    int? maxMembers,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      inviteCode: inviteCode ?? this.inviteCode,
      isPrivate: isPrivate ?? this.isPrivate,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}

// Extension to add copyWith method to GroupSubmission
extension GroupSubmissionCopyWith on GroupSubmission {
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
