import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../data/models/match_model.dart';
import '../services/mock_data_service.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart' as app_auth; // Alias to avoid conflict

class MatchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  app_auth.AuthProvider? _authProvider; // Use alias
  final SubscriptionService _subscriptionService = SubscriptionService();

  MatchProvider();

  void updateAuth(app_auth.AuthProvider auth) {
    _authProvider = auth;
    notifyListeners();
  }

  List<MatchModel> _matches = [];
  MatchModel? _selectedMatch;
  MatchModel? _matchOfTheDay;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MatchModel> get matches => _matches;
  MatchModel? get selectedMatch => _selectedMatch;
  MatchModel? get matchOfTheDay => _matchOfTheDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load matches from Firestore (Source of Truth)
  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Load Match of the Day concurrently
    loadMatchOfTheDay();
    
    try {
      // 1. Fetch Matches from Firestore
      final snapshot = await _firestoreService.firestore
          .collection('matches')
          .orderBy('matchDate', descending: true) // Show newest matches first? Or closest to now?
          // For now, let's just get them all and sort or rely on order
          .get();

      var fetchedMatches = snapshot.docs
          .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id; 
              return MatchModel.fromMap(data);
          })
          .toList();

      debugPrint('MatchProvider: Fetched ${fetchedMatches.length} matches from Firestore');

      // Sort by date manually if needed, or rely on Query
      fetchedMatches.sort((a, b) => b.matchDate.compareTo(a.matchDate));

      // Apply Subscription Limit
      // Subscription limit removed for testing/fixing display
      // if (_authProvider != null && _authProvider!.userProfile != null) {
      //   final subType = _authProvider!.userProfile!.subscriptionType;
      //   final limit = _subscriptionService.getMatchViewLimit(subType);
      //   
      //   if (fetchedMatches.length > limit) {
      //     fetchedMatches = fetchedMatches.sublist(0, limit);
      //   }
      // } else {
      //    if (fetchedMatches.isNotEmpty) {
      //      fetchedMatches = fetchedMatches.sublist(0, 1);
      //    }
      // }

      // 2. Set State
      _matches = fetchedMatches;
      
    } catch (e) {
      debugPrint('MatchProvider Error: $e');
      _errorMessage = 'Failed to load matches: $e';
      _matches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Match of the Day from Firestore
  Future<void> loadMatchOfTheDay() async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection('matches')
          .where('isMatchOfTheDay', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _matchOfTheDay = MatchModel.fromMap(snapshot.docs.first.data());
        // Add ID if fromMap doesn't extract it from doc ID (it does via 'id' argument usually, but in model it takes map['id'])
        // Let's ensure ID is correct
        _matchOfTheDay = MatchModel.fromMap(snapshot.docs.first.data()).copyWith(id: snapshot.docs.first.id);
      } else {
        _matchOfTheDay = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Match of the Day: $e');
    }
  }

  // Helper alias if needed by older code, but preferably remove usage
  Future<void> loadLiveMatches() => loadMatches();

  // Select match
  void selectMatch(MatchModel match) {
    _selectedMatch = match;
    notifyListeners();
  }

  // Listen to selected match updates
  void listenToMatch(String matchId) {
    _firestoreService.getMatch(matchId).listen(
          (match) {
        if (match != null) {
          _selectedMatch = match;
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}