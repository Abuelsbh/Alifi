import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import 'improved_firebase_wrapper.dart';


class AuthService {
  static FirebaseAuth get _auth {
    if (FirebaseConfig.isDemoMode) {
      throw Exception('Authentication not available in demo mode');
    }
    return FirebaseConfig.auth;
  }
  
  static FirebaseFirestore get _firestore {
    if (FirebaseConfig.isDemoMode) {
      throw Exception('Firestore not available in demo mode');
    }
    return FirebaseConfig.firestore;
  }

  // Get current user
  static User? get currentUser => ImprovedFirebaseWrapper.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => ImprovedFirebaseWrapper.authStateChanges;

  // Sign in with email and password
  static Future<SafeUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (FirebaseConfig.isDemoMode) {
      print('Demo mode: Sign in with $email');
      // Simulate successful login
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Demo mode: Authentication not available. Please configure Firebase.');
    }
    
    try {
      final credential = await ImprovedFirebaseWrapper.signInSafely(
        email: email,
        password: password,
      );
      
      // Update last login time
      await _updateLastLogin(credential.safeUser.uid);
      
      return credential;
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Create user with email and password
  static Future<SafeUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      print('🔵 Creating user account for: $email');
      
      final credential = await ImprovedFirebaseWrapper.createUserSafely(
        email: email,
        password: password,
      );

      print('✅ User account created successfully. UID: ${credential.safeUser.uid}');
      
      // Update display name in Firebase Auth
      await credential.safeUser.updateDisplayName(name);
      
      print('🔵 Creating user profile in Firestore...');

      // Try to create user profile in Firestore (non-blocking)
      try {
        await _createUserProfile(
          uid: credential.safeUser.uid,
          email: email,
          name: name,
          phone: phone,
        );
        print('✅ User profile created successfully in Firestore');
      } catch (firestoreError) {
        print('⚠️ Firestore error (non-critical): $firestoreError');
        // Continue anyway - Firebase Auth succeeded
      }

      return credential;
    } catch (e) {
      print('❌ Error creating user: $e');
      throw Exception(_handleAuthError(e));
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await ImprovedFirebaseWrapper.signOut();
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

    // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await ImprovedFirebaseWrapper.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final userData = <String, dynamic>{};
      
      if (name != null) userData['username'] = name; // Changed to 'username'
      if (phone != null) userData['phoneNumber'] = phone; // Changed to 'phoneNumber'
      if (photoUrl != null) userData['profilePhoto'] = photoUrl; // Changed to 'profilePhoto'
      
      userData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .update(userData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user profile - Simple version without complex models
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          data['uid'] = doc.id; // Add the document ID
          return data;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null; // Don't throw error, just return null
    }
  }

  // Create user profile in Firestore
  static Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email,
        'username': name,
        'phoneNumber': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      print('🔵 Saving user data to Firestore: $email');

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData);
          
      print('✅ User data saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving user profile to Firestore: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Update last login time
  static Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for this, as it's not critical
      print('Failed to update last login: $e');
    }
  }

  // Handle Firebase Auth errors
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }

  // Check if user is authenticated
  static bool get isAuthenticated {
    if (FirebaseConfig.isDemoMode) {
      // In demo mode, simulate being logged in
      return true;
    }
    return currentUser != null;
  }

  // Get user ID
  static String? get userId {
    if (FirebaseConfig.isDemoMode) {
      return 'demo_user_123';
    }
    return currentUser?.uid;
  }

  // Get user email
  static String? get userEmail {
    if (FirebaseConfig.isDemoMode) {
      return 'demo@example.com';
    }
    return currentUser?.email;
  }

  // Get user display name
  static String? get userDisplayName {
    if (FirebaseConfig.isDemoMode) {
      return 'Demo User';
    }
    return currentUser?.displayName;
  }

  // Get user photo URL
  static String? get userPhotoURL {
    if (FirebaseConfig.isDemoMode) {
      return null;
    }
    return currentUser?.photoURL;
  }

  // Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      final uid = currentUser?.uid;
      if (uid != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(uid).delete();
        
        // Delete user authentication
        await currentUser?.delete();
      }
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Update email
  static Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.updateEmail(newEmail);
      
      // Update email in Firestore
      if (currentUser?.uid != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update({
          'email': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }
} 