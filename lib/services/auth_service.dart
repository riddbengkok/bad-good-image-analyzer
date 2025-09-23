import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      });

      // Check if user is already signed in
      _currentUser = _auth.currentUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('DEBUG: AuthService - Starting Google sign-in...');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Trigger the authentication flow
      print('DEBUG: AuthService - Triggering Google sign-in flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('DEBUG: AuthService - Google user result: $googleUser');
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('DEBUG: AuthService - User cancelled sign-in');
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtain the auth details from the request
      print('DEBUG: AuthService - Getting Google authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('DEBUG: AuthService - Google auth details obtained');

      // Create a new credential
      print('DEBUG: AuthService - Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      print('DEBUG: AuthService - Signing in to Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('DEBUG: AuthService - Firebase sign-in successful: ${userCredential.user?.email}');
      
      // Save login state to SharedPreferences for persistence
      await _saveLoginState(true);
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
      print('DEBUG: AuthService - Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      // Clear login state from SharedPreferences
      await _saveLoginState(false);
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user display name
  String? get userDisplayName => _currentUser?.displayName;

  // Get user email
  String? get userEmail => _currentUser?.email;

  // Get user photo URL
  String? get userPhotoURL => _currentUser?.photoURL;

  // Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', isLoggedIn);
      if (isLoggedIn && _currentUser != null) {
        await prefs.setString('user_email', _currentUser!.email ?? '');
        await prefs.setString('user_display_name', _currentUser!.displayName ?? '');
        await prefs.setString('user_photo_url', _currentUser!.photoURL ?? '');
      } else {
        await prefs.remove('user_email');
        await prefs.remove('user_display_name');
        await prefs.remove('user_photo_url');
      }
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
      await _currentUser?.reload();
      _currentUser = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh user data: ${e.toString()}';
      notifyListeners();
    }
  }
}
