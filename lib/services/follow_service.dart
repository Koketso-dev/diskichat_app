import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get User Follows (and subscription status)
  Future<Map<String, dynamic>> getUserFollows(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        // Return structured data similar to what the API returned, or what app expects
        // App expects 'data' which usually contains 'followingTeams' (list of IDs) and 'subscription'
        
        return {
          'followingTeams': data['followingTeams'] ?? [],
          'followingLeagues': data['followingLeagues'] ?? [],
          'subscription': data['subscriptionType'] ?? 'FREE', // Fallback
          // Add other fields if app uses them from this specific call
        };
      }
      return {
        'followingTeams': [],
        'followingLeagues': [],
        'subscription': 'FREE',
      };
    } catch (e) {
      throw Exception('Error fetching follows: $e');
    }
  }

  // Follow Team
  Future<void> followTeam(String userId, int teamId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'followingTeams': FieldValue.arrayUnion([teamId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If doc doesn't exist (edge case), set it
      // But user should exist. If update fails, rethrow.
      debugPrint("Error following team: $e");
      rethrow;
    }
  }

  // Unfollow Team
  Future<void> unfollowTeam(String userId, int teamId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'followingTeams': FieldValue.arrayRemove([teamId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
       debugPrint("Error unfollowing team: $e");
       rethrow;
    }
  }

  // Follow League
  Future<void> followLeague(String userId, int leagueId) async {
    try {
       await _firestore.collection('users').doc(userId).update({
        'followingLeagues': FieldValue.arrayUnion([leagueId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
       rethrow;
    }
  }
}
