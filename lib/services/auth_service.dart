import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Email/Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with Email/Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create preliminary profile - REMOVED to force Wizard flow
    // if (credential.user != null) {
    //   await createUserProfile(credential.user!);
    // }
    
    return credential;
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(User user) async {
    final userModel = UserModel(
      id: user.uid,
      username: 'user_${user.uid.substring(0, 8)}',
      displayName: user.displayName ?? 'Football Fan',
      phoneNumber: user.phoneNumber ?? '',
      avatarUrl: user.photoURL,
      rank: 'amateur',
      points: 0,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? favoriteTeam,
    String? favoriteTeamLogo,
    String? country,
    String? bio,
    String? subscriptionType,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (favoriteTeam != null) updates['favoriteTeam'] = favoriteTeam;
      if (favoriteTeamLogo != null) updates['favoriteTeamLogo'] = favoriteTeamLogo;
      if (country != null) updates['country'] = country;
      if (bio != null) updates['bio'] = bio;
      if (subscriptionType != null) updates['subscriptionType'] = subscriptionType;

      await _firestore.collection('users').doc(userId).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user points
  Future<void> updateUserPoints(String userId, int pointsToAdd) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(pointsToAdd),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating points: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(userId).delete();

        // Delete Firebase Auth account
        await currentUser?.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}