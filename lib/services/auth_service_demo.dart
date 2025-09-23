import 'package:flutter/foundation.dart';

// Demo authentication service for testing without Firebase
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userDisplayName;
  String? _userEmail;
  String? _userPhotoURL;

  bool get isAuthenticated => _isAuthenticated;
  String? get userDisplayName => _userDisplayName;
  String? get userEmail => _userEmail;
  String? get userPhotoURL => _userPhotoURL;
  bool get isSignedIn => _isAuthenticated;

  // Stream to listen to authentication state changes (demo version)
  Stream<bool> get authStateChanges => Stream.periodic(
    const Duration(milliseconds: 100),
    (_) => _isAuthenticated,
  ).takeWhile((_) => true);

  // Demo sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Demo user data
      _userDisplayName = 'Demo User';
      _userEmail = 'demo@example.com';
      _userPhotoURL = 'https://via.placeholder.com/150/007AFF/FFFFFF?text=U';
      _isAuthenticated = true;
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Demo sign in error: $e');
      return false;
    }
  }

  // Demo sign out
  Future<void> signOut() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isAuthenticated = false;
      _userDisplayName = null;
      _userEmail = null;
      _userPhotoURL = null;
      
      notifyListeners();
    } catch (e) {
      print('Demo sign out error: $e');
    }
  }
}
