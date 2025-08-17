import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _createUserProfile(
          userId: userCredential.user!.uid,
          email: email,
          username: username,
        );
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    final userData = {
      'email': email,
      'username': username,
      'profilePhoto': null,
      'phoneNumber': null,
      'address': null,
      'pets': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(userId).set(userData);
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? profilePhoto,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (username != null) updateData['username'] = username;
      if (profilePhoto != null) updateData['profilePhoto'] = profilePhoto;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Add pet to user profile
  Future<void> addPetToProfile({
    required String userId,
    required PetModel pet,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'pets': FieldValue.arrayUnion([pet.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding pet to profile: $e');
      throw Exception('Failed to add pet');
    }
  }

  // Update pet in user profile
  Future<void> updatePetInProfile({
    required String userId,
    required PetModel pet,
  }) async {
    try {
      // Get current user data
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        UserModel user = UserModel.fromFirestore(doc);
        List<PetModel> updatedPets = user.pets.map((p) {
          if (p.id == pet.id) {
            return pet;
          }
          return p;
        }).toList();

        await _firestore.collection('users').doc(userId).update({
          'pets': updatedPets.map((pet) => pet.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating pet in profile: $e');
      throw Exception('Failed to update pet');
    }
  }

  // Delete pet from user profile
  Future<void> deletePetFromProfile({
    required String userId,
    required String petId,
  }) async {
    try {
      // Get current user data
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        UserModel user = UserModel.fromFirestore(doc);
        List<PetModel> updatedPets = user.pets.where((p) => p.id != petId).toList();

        await _firestore.collection('users').doc(userId).update({
          'pets': updatedPets.map((pet) => pet.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error deleting pet from profile: $e');
      throw Exception('Failed to delete pet');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
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
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
} 