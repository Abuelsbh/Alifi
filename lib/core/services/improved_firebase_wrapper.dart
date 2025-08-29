import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';

class ImprovedFirebaseWrapper {
  // Safe authentication methods
  static User? get currentUser {
    if (FirebaseConfig.isDemoMode) {
      return null; // Return null in demo mode
    }
    try {
      return FirebaseConfig.auth.currentUser;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  static Stream<User?> get authStateChanges {
    if (FirebaseConfig.isDemoMode) {
      // Return empty stream in demo mode
      return Stream.value(null);
    }
    try {
      return FirebaseConfig.auth.authStateChanges();
    } catch (e) {
      print('❌ Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }

  // Safe sign in
  static Future<SafeUserCredential> signInSafely({
    required String email,
    required String password,
  }) async {
    if (FirebaseConfig.isDemoMode) {
      throw Exception('Authentication not available in demo mode');
    }
    
    try {
      final credential = await FirebaseConfig.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return SafeUserCredential(credential);
    } catch (e) {
      print('❌ Error signing in: $e');
      rethrow;
    }
  }

  // Safe user creation
  static Future<SafeUserCredential> createUserSafely({
    required String email,
    required String password,
  }) async {
    if (FirebaseConfig.isDemoMode) {
      throw Exception('Authentication not available in demo mode');
    }
    
    try {
      final credential = await FirebaseConfig.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return SafeUserCredential(credential);
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    }
  }

  // Safe sign out
  static Future<void> signOut() async {
    if (FirebaseConfig.isDemoMode) {
      print('Demo mode: Sign out simulated');
      return;
    }
    
    try {
      await FirebaseConfig.auth.signOut();
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // Safe password reset
  static Future<void> sendPasswordResetEmail(String email) async {
    if (FirebaseConfig.isDemoMode) {
      print('Demo mode: Password reset email would be sent to $email');
      return;
    }
    
    try {
      await FirebaseConfig.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      rethrow;
    }
  }
}

// Wrapper class for UserCredential
class SafeUserCredential {
  final UserCredential _credential;
  
  SafeUserCredential(this._credential);
  
  SafeUser get safeUser => SafeUser(_credential.user!);
  
  UserCredential get credential => _credential;
}

// Wrapper class for User
class SafeUser {
  final User _user;
  
  SafeUser(this._user);
  
  String get uid => _user.uid;
  String? get email => _user.email;
  String? get displayName => _user.displayName;
  String? get photoURL => _user.photoURL;
  bool get emailVerified => _user.emailVerified;
  
  Future<void> updateDisplayName(String? displayName) async {
    try {
      await _user.updateDisplayName(displayName);
    } catch (e) {
      print('❌ Error updating display name: $e');
      rethrow;
    }
  }
  
  Future<void> updateEmail(String newEmail) async {
    try {
      await _user.updateEmail(newEmail);
    } catch (e) {
      print('❌ Error updating email: $e');
      rethrow;
    }
  }
  
  Future<void> updatePassword(String newPassword) async {
    try {
      await _user.updatePassword(newPassword);
    } catch (e) {
      print('❌ Error updating password: $e');
      rethrow;
    }
  }
  
  Future<void> sendEmailVerification() async {
    try {
      await _user.sendEmailVerification();
    } catch (e) {
      print('❌ Error sending email verification: $e');
      rethrow;
    }
  }
  
  Future<void> delete() async {
    try {
      await _user.delete();
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }
} 