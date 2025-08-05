import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';
import 'package:snack_hack_app/core/services/guest_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChallengeSubmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Check if current user is a guest
  static Future<bool> _isGuestUser() async {
    return _userId == null && await GuestUserService.isGuestSessionValid();
  }

  static Future<void> saveSubmission(ChallengeSubmission submission) async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) {
      print('❌ SUBMISSION: No user ID available');
      return;
    }

    print('📸 SUBMISSION: Saving challenge submission...');
    print('   - Challenge: ${submission.submissionTitle}');
    print('   - Description: ${submission.submissionDescription}');
    print('   - Image: ${submission.imageUrl}');
    print('   - Date: ${submission.submittedAt}');
    print('   - User ID: $_userId');
    print('   - Is Guest: $isGuest');

    if (isGuest) {
      // Guest user - save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final submissionKey =
          'guest_submission_${submission.submittedAt.toIso8601String()}';
      await prefs.setString(submissionKey, jsonEncode(submission.toJson()));
      print('✅ SUBMISSION: Guest submission saved to SharedPreferences!');
    } else {
      // Firebase user - save to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('submissions')
          .doc(submission.submittedAt.toIso8601String())
          .set(submission.toJson());
      print('✅ SUBMISSION: Challenge submission saved successfully!');
    }
  }

  static Future<ChallengeSubmission?> getSubmissionForDate(
    DateTime date,
  ) async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return null;

    if (isGuest) {
      // Guest user - get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final submissionKey = 'guest_submission_${date.toIso8601String()}';
      final submissionData = prefs.getString(submissionKey);

      if (submissionData == null) return null;

      try {
        final submissionMap =
            jsonDecode(submissionData) as Map<String, dynamic>;
        return ChallengeSubmission.fromJson(submissionMap);
      } catch (e) {
        print('❌ SUBMISSION ERROR: Failed to parse guest submission data: $e');
        return null;
      }
    } else {
      // Firebase user - get from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('submissions')
          .doc(date.toIso8601String())
          .get();

      if (!doc.exists) return null;
      return ChallengeSubmission.fromJson(doc.data()!);
    }
  }

  static Future<List<ChallengeSubmission>> getAllSubmissions() async {
    final isGuest = await _isGuestUser();

    if (_userId == null && !isGuest) return [];

    if (isGuest) {
      // Guest user - get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final submissionKeys = keys
          .where((key) => key.startsWith('guest_submission_'))
          .toList();

      final submissions = <ChallengeSubmission>[];
      for (final key in submissionKeys) {
        try {
          final submissionData = prefs.getString(key);
          if (submissionData != null) {
            final submissionMap =
                jsonDecode(submissionData) as Map<String, dynamic>;
            submissions.add(ChallengeSubmission.fromJson(submissionMap));
          }
        } catch (e) {
          print('❌ SUBMISSION ERROR: Failed to parse guest submission: $e');
        }
      }

      // Sort by submittedAt descending
      submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return submissions;
    } else {
      // Firebase user - get from Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeSubmission.fromJson(doc.data()))
          .toList();
    }
  }
}
