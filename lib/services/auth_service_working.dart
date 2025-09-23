import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userDisplayName;
  String? _userPhotoURL;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userEmail;
  String? get userDisplayName => _userDisplayName;
  String? get userPhotoURL => _userPhotoURL;

  // Stream to listen to authentication state changes
  Stream<bool> get authStateChanges async* {
    yield _isAuthenticated;
  }

  AuthService() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user was previously logged in
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (wasLoggedIn) {
        _isAuthenticated = true;
        _userEmail = prefs.getString('user_email') ?? 'user@example.com';
        _userDisplayName = prefs.getString('user_display_name') ?? 'Demo User';
        _userPhotoURL = prefs.getString('user_photo_url');
        print('DEBUG: User was previously logged in: $_userEmail');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google (simulated but working)
  Future<bool> signInWithGoogle() async {
    try {
      print('DEBUG: AuthService - Starting Google sign-in...');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate Google sign-in process with realistic delay
      await Future.delayed(const Duration(seconds: 2));
      
      // For demo purposes, create a mock user
      _userEmail = 'user@example.com';
      _userDisplayName = 'Demo User';
      _userPhotoURL = null;
      _isAuthenticated = true;
      
      // Save login state to SharedPreferences for persistence
      await _saveLoginState(true);
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      print('DEBUG: AuthService - Sign-in successful: $_userEmail');
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
      print('DEBUG: AuthService - Error signing in: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate sign out process
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clear user data
      _isAuthenticated = false;
      _userEmail = null;
      _userDisplayName = null;
      _userPhotoURL = null;
      
      // Clear login state from SharedPreferences
      await _saveLoginState(false);
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      print('DEBUG: AuthService - Sign-out successful');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
      print('DEBUG: AuthService - Error signing out: $e');
    }
  }

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', isLoggedIn);
      if (isLoggedIn) {
        await prefs.setString('user_email', _userEmail ?? '');
        await prefs.setString('user_display_name', _userDisplayName ?? '');
        await prefs.setString('user_photo_url', _userPhotoURL ?? '');
      } else {
        await prefs.remove('user_email');
        await prefs.remove('user_display_name');
        await prefs.remove('user_photo_url');
      }
      print('DEBUG: AuthService - Login state saved: $isLoggedIn');
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  // Check if user was previously logged in
  Future<bool> wasUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('Error checking login state: $e');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      // Simulate refresh
      await Future.delayed(const Duration(milliseconds: 500));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh user data: ${e.toString()}';
      notifyListeners();
    }
  }
}
