import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../data/models/message_model.dart';
import '../utils/constants/app_constants.dart';
import 'dart:io';
import '../services/image_upload_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<MessageModel> _messages = [];
  int _activeUsersCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, String?> _userVotes = {}; // messageId -> voteType

  // Getters
  List<MessageModel> get messages => _messages;
  int get activeUsersCount => _activeUsersCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load messages for a match
  void loadMessages(String matchId) {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getMatchMessages(matchId).listen(
          (messages) {
        _messages = messages;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load active users count
  void loadActiveUsersCount(String matchId) {
    _firestoreService.getActiveUsersCount(matchId).listen(
          (count) {
        _activeUsersCount = count;
        notifyListeners();
      },
    );
  }

  final ImageUploadService _imageUploadService = ImageUploadService();

  // Send message
  Future<bool> sendMessage({
    required String matchId,
    required String message,
    String messageType = 'comment',
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final messageModel = MessageModel(
        id: const Uuid().v4(),
        matchId: matchId,
        userId: user.uid,
        message: message,
        messageType: messageType,
        votes: 0,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
      );

      await _firestoreService.sendMessage(matchId, messageModel);

      // Award points for sending message
      await _authService.updateUserPoints(
        user.uid,
        AppConstants.pointsPerMessage,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send Media Message
  Future<bool> sendMediaMessage({
    required String matchId,
    required File file,
    required bool isVideo,
    String? message,
  }) async {
      _isLoading = true;
      notifyListeners();
      
      try {
        String? imageUrl;
        String? videoUrl;
        String? thumbnailUrl;

        if (isVideo) {
             videoUrl = await _imageUploadService.uploadVideo(file, folder: 'chat_media/$matchId');
        } else {
             imageUrl = await _imageUploadService.uploadImage(file, folder: 'chat_media/$matchId');
        }

        final success = await sendMessage(
            matchId: matchId, 
            message: message ?? (isVideo ? 'Sent a video' : 'Sent a photo'),
            messageType: 'comment', // Or specific type
            imageUrl: imageUrl,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
        );
        
        _isLoading = false;
        notifyListeners();
        return success;
      } catch (e) {
          _errorMessage = e.toString();
          _isLoading = false;
          notifyListeners();
          return false;
      }
  }

  // Delete Message
  Future<bool> deleteMessage({required String matchId, required String messageId}) async {
    try {
      await _firestoreService.deleteMessage(matchId, messageId);
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages.removeAt(index);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Edit Message
  Future<bool> editMessage({required String matchId, required String messageId, required String newContent}) async {
    try {
      await _firestoreService.updateMessage(matchId, messageId, newContent);
      // Local update for immediate feedback (though stream will also update)
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(message: newContent); // Ensure copyWith exists and is used/added if needed or just rely on stream
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle Reaction
  Future<void> toggleReaction({
    required String matchId,
    required String messageId,
    required String emoji,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _firestoreService.toggleReaction(
        matchId: matchId,
        messageId: messageId,
        userId: user.uid,
        emoji: emoji,
      );
      // No need to notifyListeners() immediately as we listen to the stream
    } catch (e) {
      debugPrint("Error toggling reaction: $e");
    }
  }

  // Vote on message (Legacy)
  Future<void> voteMessage({
    required String matchId,
    required String messageId,
    required String voteType,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _firestoreService.voteMessage(
        matchId: matchId,
        messageId: messageId,
        userId: user.uid,
        voteType: voteType,
      );

      // Update local vote state
      _userVotes[messageId] = voteType;
      notifyListeners();

      // Award/deduct points
      if (voteType == 'up') {
        await _authService.updateUserPoints(
          user.uid,
          AppConstants.pointsPerUpvote,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get user's vote on a message
  String? getUserVote(String messageId) {
    return _userVotes[messageId];
  }

  final Set<String> _joinedMatchIds = {};

  // Check if joined
  bool isJoined(String matchId) => _joinedMatchIds.contains(matchId);

  // Join room
  Future<void> joinRoom(String matchId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (_joinedMatchIds.contains(matchId)) {
      // Already joined locally, just ensure backend is updated (without erroring)
      await _firestoreService.joinRoom(matchId, user.uid, checkLimit: false);
    } else {
      // New join
      await _firestoreService.joinRoom(matchId, user.uid, checkLimit: true);
      _joinedMatchIds.add(matchId);
      notifyListeners();
    }
  }

  // Leave room
  Future<void> leaveRoom(String matchId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _firestoreService.leaveRoom(matchId, user.uid);
    _joinedMatchIds.remove(matchId);
    notifyListeners();
  }

  // Update last active
  Future<void> updateLastActive(String matchId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _firestoreService.updateLastActive(matchId, user.uid);
  }

  // Clear messages
  void clearMessages() {
    _messages = [];
    _activeUsersCount = 0;
    _userVotes.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}