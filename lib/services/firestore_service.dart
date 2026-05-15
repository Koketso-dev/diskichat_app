import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/match_model.dart';
import '../data/models/message_model.dart';
import '../data/models/post_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/feedback_model.dart';
import '../data/models/lineup_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;

  // ========== MATCHES ==========

  // Get all matches
  Stream<List<MatchModel>> getMatches() {
    return _firestore
        .collection('matches')
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data()))
        .toList());
  }

  // Get live matches
  Stream<List<MatchModel>> getLiveMatches() {
    return _firestore
        .collection('live_matches')
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data()))
        .toList());
  }

  // Get matches by date
  Stream<List<MatchModel>> getMatchesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('matches')
        .where('matchDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('matchDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data()))
        .toList());
  }

  // Get matches by competition
  Stream<List<MatchModel>> getMatchesByCompetition(String competitionId) {
    return _firestore
        .collection('matches')
        .where('competitionId', isEqualTo: competitionId)
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data()))
        .toList());
  }

  // Get single match
  Stream<MatchModel?> getMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromMap(doc.data()!) : null);
  }

  // Add match (admin only - for testing)
  Future<void> addMatch(MatchModel match) async {
    await _firestore.collection('matches').doc(match.id).set(match.toMap());
  }

  // Get Lineups from Match Document
  Future<List<LineupModel>> getLineups(String matchId) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('lineups')) {
          final List<dynamic> lineupsJson = data['lineups'];
          return lineupsJson.map((json) => LineupModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching lineups: $e');
      return [];
    }
  }

  // Update match score
  Future<void> updateMatchScore(String matchId, int homeScore, int awayScore) async {
    await _firestore.collection('matches').doc(matchId).update({
      'scoreHome': homeScore,
      'scoreAway': awayScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update match status
  Future<void> updateMatchStatus(String matchId, String status) async {
    await _firestore.collection('matches').doc(matchId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== MESSAGES ==========

  // Get messages for a match
  Stream<List<MessageModel>> getMatchMessages(String matchId, {int limit = 50}) {
    return _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()))
        .toList()
        .reversed
        .toList());
  }

  // Send message
  Future<void> sendMessage(String matchId, MessageModel message) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  // Update message votes
  Future<void> updateMessageVotes(String matchId, String messageId, int votes) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'votes': votes,
    });
  }

  // Update message content
  Future<void> updateMessage(String matchId, String messageId, String newContent) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': newContent,
      'isEdited': true, // Optional flag to show (edited)
    });
  }

  // Delete message
  Future<void> deleteMessage(String matchId, String messageId) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Vote on message (Legacy)
  Future<void> voteMessage({
    required String matchId,
    required String messageId,
    required String userId,
    required String voteType, // 'up' or 'down'
  }) async {
    // ... existing implementation ...
     final voteRef = _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .collection('votes')
        .doc(userId);

    final voteDoc = await voteRef.get();

    if (voteDoc.exists) {
      // User already voted, remove vote or change vote
      final existingVote = voteDoc.data()?['type'];
      if (existingVote == voteType) {
        // Same vote, remove it
        await voteRef.delete();
        await _updateVoteCount(matchId, messageId, voteType == 'up' ? -1 : 1);
      } else {
        // Different vote, change it
        await voteRef.update({'type': voteType});
        await _updateVoteCount(matchId, messageId, voteType == 'up' ? 2 : -2);
      }
    } else {
      // New vote
      await voteRef.set({
        'type': voteType,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _updateVoteCount(matchId, messageId, voteType == 'up' ? 1 : -1);
    }
  }

  // Toggle Reaction
  Future<void> toggleReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final messageRef = _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId);

    // Run transaction to ensure atomic update of the map
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});

      if (reactions[userId] == emoji) {
        // Remove if same emoji
        reactions.remove(userId);
      } else {
        // Update/Add if different or new
        reactions[userId] = emoji;
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  Future<void> _updateVoteCount(String matchId, String messageId, int change) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'votes': FieldValue.increment(change),
    });
  }

  // Get user's vote on a message
  Future<String?> getUserVote(String matchId, String messageId, String userId) async {
     // ... existing implementation ...
    final voteDoc = await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .collection('votes')
        .doc(userId)
        .get();

    if (voteDoc.exists) {
        final data = voteDoc.data();
        if (data != null) {
             return data['type'];
        }
    }
    return null;
  }

  // ========== ROOM ACTIVITY ==========

  // Join room
  Future<void> joinRoom(String matchId, String userId, {bool checkLimit = true}) async {
    final activeUsersRef = _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('activeUsers');

    if (checkLimit) {
      // Check count first
      final countQuery = await activeUsersRef.count().get();
      final count = countQuery.count ?? 0;

      if (count >= 100) {
        throw Exception('Room is full (100/100 users). Try again later.');
      }
    }

    await activeUsersRef.doc(userId).set({
      'userId': userId,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Merge to prevent overwriting joinedAt if needed
  }

  // Update last active
  Future<void> updateLastActive(String matchId, String userId) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('activeUsers')
        .doc(userId)
        .update({
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Leave room
  Future<void> leaveRoom(String matchId, String userId) async {
    await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('activeUsers')
        .doc(userId)
        .delete();
  }

  // Get active users count
  Stream<int> getActiveUsersCount(String matchId) {
    return _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('activeUsers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clean up inactive users (older than 5 minutes)
  Future<void> cleanupInactiveUsers(String matchId) async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    final snapshot = await _firestore
        .collection('banter_rooms')
        .doc(matchId)
        .collection('activeUsers')
        .where('lastActive', isLessThan: Timestamp.fromDate(fiveMinutesAgo))
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
  // ========== SOCIAL FEED ==========

  // Get Feed Stream
  Stream<List<PostModel>> getFeed() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> createPost(PostModel post) async {
    await _firestore.collection('posts').add(post.toMap());
  }

  // Update Post
  Future<void> updatePost(PostModel post) async {
    await _firestore.collection('posts').doc(post.id).update({
      'content': post.content,
      'imageUrl': post.imageUrl,
      'videoUrl': post.videoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
    // Ideally we should delete subcollections (comments, likes) via Cloud Functions
  }

  // Like Post (with Gamification)
  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    final likeDoc = await likeRef.get();
    if (likeDoc.exists) {
      // Unlike
      await likeRef.delete();
      await postRef.update({'likesCount': FieldValue.increment(-1)});
      // Note: We don't deduct points on unlike to avoid negative sentiment,
      // but typically gamification is strictly additive or we can deduct.
      // For now, let's keep it additive (only award on first like) OR deduct.
      // Let's deduct to prevent spam toggling.
      final postDoc = await postRef.get();
      final ownerId = postDoc.data()?['userId'];
      if (ownerId != null) {
          await _awardPoints(ownerId, -5); // Deduct 5 Diski
      }
    } else {
      // Like
      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await postRef.update({'likesCount': FieldValue.increment(1)});
      
      // Award Diski to Post Owner
      final postDoc = await postRef.get();
      final ownerId = postDoc.data()?['userId'];
      if (ownerId != null && ownerId != userId) { // Don't award for self-likes
         await _awardPoints(ownerId, 5); // 5 Diski per like
      }
    }
  }

  // Check if User Liked Post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    final likeDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .get();
    return likeDoc.exists;
  }
  
  // ========== COMMENTS ==========

  // Get Comments Stream
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Add Comment (with Gamification)
  Future<void> addComment(CommentModel comment) async {
    final postRef = _firestore.collection('posts').doc(comment.postId);
    
    // Add comment
    await postRef.collection('comments').add(comment.toMap());
    
    // Update count
    await postRef.update({'commentsCount': FieldValue.increment(1)});
    
    // Check for 100 comments milestone
    final postDoc = await postRef.get();
    final currentCount = postDoc.data()?['commentsCount'] ?? 0;
    final ownerId = postDoc.data()?['userId'];

    if (currentCount == 100 && ownerId != null) {
      // Award HUGE bonus for 100 comments
       await _awardPoints(ownerId, 500); // 500 Diski
    }
  }

  // Update Comment
  Future<void> updateComment(String postId, String commentId, String content) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Comment
  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    
    await postRef.collection('comments').doc(commentId).delete();
    
    // Decrement count
    await postRef.update({'commentsCount': FieldValue.increment(-1)});
  }

  // ========== GAMIFICATION ==========
  
  Future<void> _awardPoints(String userId, int points) async {
    final userRef = _firestore.collection('users').doc(userId);
    await userRef.update({
      'points': FieldValue.increment(points),
    });
  }

  // ========== FEEDBACK ==========

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _firestore.collection('feedback').add(feedback.toMap());
  }

  // ========== ANALYTICS ==========

  Future<void> logSubscriptionAttempt(String userId, String plan) async {
    await _firestore.collection('subscription_attempts').add({
      'userId': userId,
      'plan': plan,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}