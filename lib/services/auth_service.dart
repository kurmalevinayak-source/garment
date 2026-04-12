import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Manages Firebase Authentication state.
///
/// Uses [ChangeNotifier] so it can be used with Provider for
/// reactive UI updates when auth state changes.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Current user ─────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Auth state stream ────────────────────────────────────
  /// Stream that emits on every sign-in / sign-out event.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign In ──────────────────────────────────────────────
  /// Signs in with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signIn(String email, String password) async {
    try {
      // 1. Ensure Firebase is fully initialized before proceeding
      if (Firebase.apps.isEmpty) {
        return 'System Error: Firebase is not initialized. Please restart the app.';
      }

      // 2. Properly await the Firebase auth method
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      notifyListeners();
      return null; // success
      
    } on FirebaseAuthException catch (e) {
      // 3. Handle specific Firebase error codes
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────
  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ─── Register (optional — for creating the first admin) ───
  /// Creates a new user account with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> register(String email, String password) async {
    try {
      if (Firebase.apps.isEmpty) {
        return 'System Error: Firebase is not initialized.';
      }
      
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // ─── Error message mapping ────────────────────────────────
  /// Maps Firebase error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Error code: $code';
    }
  }
}
