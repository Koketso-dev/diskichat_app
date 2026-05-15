import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../data/models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  // Getters
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  // Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _authService.getUserProfile(_user!.uid);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign in with Mobile (Pseudo-Email)
  Future<bool> signInWithMobile(String mobileNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create pseudo-email
      // Remove any spaces or special chars from mobile just in case
      final cleanMobile = mobileNumber.replaceAll(RegExp(r'\s+'), '');
      final email = '$cleanMobile@diskichatapp.app';
      const password = 'userPassword123!'; // Hardcoded for prototype as requested

      try {
        // Attempt Sign In
        UserCredential credential = await _authService.signInWithEmail(
          email: email,
          password: password,
        );
        _user = credential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // User doesn't exist, create account
          UserCredential credential = await _authService.signUpWithEmail(
            email: email,
            password: password,
          );
          _user = credential.user;
        } else {
          rethrow;
        }
      }

      await loadUserProfile();
      
      // Safety Check: If profile is still null (e.g. deleted or failed creation), recreate it
      // Profile check
      // If profile is null, WelcomeAuthScreen will handle redirection to ProfileWizard

      _isLoading = false;
      notifyListeners();
      
      // Save persistence flag
      await StorageService().setLoggedIn(true);
      
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? favoriteTeam,
    String? favoriteTeamLogo,
    String? country,
    String? bio,
    String? subscriptionType,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        userId: _user!.uid,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        favoriteTeam: favoriteTeam,
        favoriteTeamLogo: favoriteTeamLogo,
        country: country,
        bio: bio,
        subscriptionType: subscriptionType,
      );

      await loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    await StorageService().setLoggedIn(false);

    _user = null;
    _userProfile = null;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}