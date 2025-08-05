import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication Methods
  static Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Firestore Methods
  static Future<void> saveUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await _firestore.collection('users').doc(userId).set(userData);
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  static Future<void> saveChallenge(
    String userId,
    Map<String, dynamic> challengeData,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .add(challengeData);
  }

  static Future<List<Map<String, dynamic>>> getUserChallenges(
    String userId,
  ) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .orderBy('date', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> saveSubmission(
    String userId,
    Map<String, dynamic> submissionData,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('submissions')
        .add(submissionData);
  }

  static Future<List<Map<String, dynamic>>> getUserSubmissions(
    String userId,
  ) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // Groups Methods
  static Future<void> createGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    await _firestore.collection('groups').doc(groupId).set(groupData);
  }

  static Future<Map<String, dynamic>?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.data();
  }

  static Future<void> joinGroup(
    String groupId,
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .set(userData);
  }

  // Voting Methods
  static Future<void> saveVote(
    String groupId,
    String submissionId,
    Map<String, dynamic> voteData,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('submissions')
        .doc(submissionId)
        .collection('votes')
        .add(voteData);
  }

  // Leaderboard Methods
  static Future<List<Map<String, dynamic>>> getGroupLeaderboard(
    String groupId,
  ) async {
    final querySnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('points', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
