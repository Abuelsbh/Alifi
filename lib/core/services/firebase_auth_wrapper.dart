import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Wrapper class to handle Firebase Auth Pigeon interface issues
class FirebaseAuthWrapper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Safe wrapper for createUserWithEmailAndPassword that handles Pigeon interface issues
  static Future<UserCredential> createUserWithEmailAndPasswordSafe({
    required String email,
    required String password,
  }) async {
    try {
      // Try the normal flow first
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      developer.log('✅ User created successfully via normal flow');
      return credential;
      
    } catch (e) {
      // Check if this is the specific Pigeon interface error
      if (e.toString().contains('List<Object?>') && 
          e.toString().contains('PigeonUserDetails')) {
        
        developer.log('🔧 Handling Pigeon interface error, attempting workaround...');
        
        // The user was actually created despite the error, let's try to get it
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to sign in with the same credentials to get the UserCredential
        try {
          final signInCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          developer.log('✅ User retrieved via sign-in workaround');
          return signInCredential;
          
        } catch (signInError) {
          // If sign-in fails, the user might not have been created
          throw Exception('User creation failed: ${e.toString()}');
        }
      } else {
        // Re-throw other errors as-is
        rethrow;
      }
    }
  }

  /// Safe wrapper for signInWithEmailAndPassword
  static Future<UserCredential> signInWithEmailAndPasswordSafe({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (e.toString().contains('List<Object?>') && 
          e.toString().contains('PigeonUserDetails')) {
        
        // Wait a bit and retry
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if user is already signed in despite the error
        if (_auth.currentUser != null && _auth.currentUser!.email == email) {
          // Create a mock UserCredential since the sign-in actually succeeded
          return MockUserCredential(_auth.currentUser!);
        }
      }
      rethrow;
    }
  }

  /// Get current user safely
  static User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out safely
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

/// Mock UserCredential for cases where the operation succeeded but Pigeon failed
class MockUserCredential implements UserCredential {
  @override
  final User user;

  @override
  final AuthCredential? credential = null;

  @override
  final AdditionalUserInfo? additionalUserInfo = null;

  MockUserCredential(this.user);
}

/// Extension to safely get user from UserCredential
extension UserCredentialExtension on UserCredential {
  User get safeUser {
    final u = user;
    if (u == null) {
      throw Exception('User is null in UserCredential');
    }
    return u;
  }
} 