import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Get all registered users (excluding current user)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (_userId == null) throw Exception('User not authenticated');

    print('👥 USER SERVICE: Fetching all users...');
    print('👥 USER SERVICE: Current user ID: $_userId');

    try {
      final querySnapshot = await _firestore.collection('users').get();
      print(
        '👥 USER SERVICE: Total documents in users collection: ${querySnapshot.docs.length}',
      );

      // Log all document IDs for debugging
      for (final doc in querySnapshot.docs) {
        print('👥 USER SERVICE: Found document ID: ${doc.id}');
        print('👥 USER SERVICE: Document data: ${doc.data()}');
      }

      final users = querySnapshot.docs
          .where((doc) => doc.id != _userId) // Exclude current user
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Unknown User',
              'email': doc.data()['email'] ?? '',
              'points': doc.data()['points'] ?? 0,
              'streak': doc.data()['streak'] ?? 0,
              'earnedBadges': doc.data()['earnedBadges'] ?? [],
            },
          )
          .toList();

      print(
        '👥 USER SERVICE: Found ${users.length} users (excluding current user)',
      );
      print('👥 USER SERVICE: Users list: $users');
      return users;
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Search users by name or email
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('🔍 USER SERVICE: Searching users with query: $query');

    try {
      final allUsers = await getAllUsers();

      final filteredUsers = allUsers.where((user) {
        final name = user['name'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();

      print('🔍 USER SERVICE: Found ${filteredUsers.length} matching users');
      return filteredUsers;
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get user details by ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('👤 USER SERVICE: Fetching user details for: $userId');

    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final userData = doc.data()!;
        return {
          'id': doc.id,
          'name': userData['name'] ?? 'Unknown User',
          'email': userData['email'] ?? '',
          'points': userData['points'] ?? 0,
          'streak': userData['streak'] ?? 0,
          'earnedBadges': userData['earnedBadges'] ?? [],
        };
      }

      return null;
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Send direct invite to user
  static Future<void> sendDirectInvite({
    required String targetUserId,
    required String groupId,
    required String groupName,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('📨 USER SERVICE: Sending direct invite to user: $targetUserId');

    try {
      // Create invite notification in target user's collection
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('invites')
          .add({
            'groupId': groupId,
            'groupName': groupName,
            'invitedBy': _userId,
            'invitedAt': DateTime.now().toIso8601String(),
            'status': 'pending', // pending, accepted, declined
          });

      print('✅ USER SERVICE: Direct invite sent successfully');
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to send invite: $e');
    }
  }

  /// Get pending invites for current user
  static Future<List<Map<String, dynamic>>> getPendingInvites() async {
    if (_userId == null) throw Exception('User not authenticated');

    print('📨 USER SERVICE: Fetching pending invites...');

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('invites')
          .where('status', isEqualTo: 'pending')
          .get();

      final invites = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'groupId': data['groupId'],
          'groupName': data['groupName'],
          'invitedBy': data['invitedBy'],
          'invitedAt': DateTime.parse(data['invitedAt']),
          'status': data['status'],
        };
      }).toList();

      print('📨 USER SERVICE: Found ${invites.length} pending invites');
      return invites;
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to fetch invites: $e');
    }
  }

  /// Accept or decline an invite
  static Future<void> respondToInvite({
    required String inviteId,
    required String response, // 'accepted' or 'declined'
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('📨 USER SERVICE: Responding to invite: $response');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('invites')
          .doc(inviteId)
          .update({
            'status': response,
            'respondedAt': DateTime.now().toIso8601String(),
          });

      print('✅ USER SERVICE: Invite response recorded');
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to respond to invite: $e');
    }
  }

  /// Add user to group when invite is accepted
  static Future<void> addUserToGroup(String groupId) async {
    if (_userId == null) throw Exception('User not authenticated');

    print('👥 USER SERVICE: Adding user to group: $groupId');
    print('👥 USER SERVICE: Current user ID: $_userId');

    try {
      // Get the group document
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      print('👥 USER SERVICE: Group data: $groupData');

      final currentMembers = List<String>.from(groupData['members'] ?? []);
      print('👥 USER SERVICE: Current members: $currentMembers');

      // Check if user is already a member
      if (currentMembers.contains(_userId)) {
        print('👥 USER SERVICE: User already a member of group');
        return;
      }

      // Add user to members list
      currentMembers.add(_userId!);
      print('👥 USER SERVICE: Updated members list: $currentMembers');

      // Update the group document
      await _firestore.collection('groups').doc(groupId).update({
        'members': currentMembers,
      });

      print('✅ USER SERVICE: User successfully added to group');

      // Verify the update
      final updatedDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();
      final updatedData = updatedDoc.data()!;
      final updatedMembers = List<String>.from(updatedData['members'] ?? []);
      print('👥 USER SERVICE: Verification - Updated members: $updatedMembers');
    } catch (e) {
      print('❌ USER SERVICE ERROR: $e');
      throw Exception('Failed to add user to group: $e');
    }
  }
}
