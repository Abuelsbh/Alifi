import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firebase_config.dart';

class VeterinaryService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseAuth _auth = FirebaseConfig.auth;

  // Create veterinarian account
  static Future<UserCredential> createVeterinarianAccount({
    required String email,
    required String password,
    required String name,
    required String specialization,
    required String experience,
    required String phone,
    String? profileImage,
    String? bio,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create veterinarian profile in users collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': name,
        'name': name, // Also store as name
        'specialization': specialization,
        'experience': experience,
        'phone': phone,
        'phoneNumber': phone, // Also store as phoneNumber
        'profileImage': profileImage,
        'profileImageUrl': profileImage, // Also store as profileImageUrl
        'profilePhoto': profileImage, // Also store as profilePhoto for compatibility
        'bio': bio,
        'isOnline': false,
        'isActive': true,
        'rating': 0.0,
        'totalRatings': 0,
        'isVerified': true,
        'userType': 'veterinarian', // Flag to identify veterinarian
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
      });

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      return userCredential;
    } catch (e) {
      throw Exception('فشل في إنشاء حساب الطبيب البيطري: $e');
    }
  }

  // Sign in veterinarian
  static Future<UserCredential> signInVeterinarian({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is a veterinarian from users collection
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('المستخدم غير موجود');
      }

      final userData = userDoc.data();
      // Check if user is a veterinarian
      if (userData?['userType'] != 'veterinarian') {
        await _auth.signOut();
        throw Exception('هذا الحساب ليس حساب طبيب بيطري');
      }

      // Check if veterinarian is deleted or inactive
      if (userData != null) {
        // Check if veterinarian is deleted
        if (userData['isDeleted'] == true) {
          await _auth.signOut();
          throw Exception('تم حذف هذا الحساب');
        }
        // Check if veterinarian is inactive
        if (userData['isActive'] == false) {
          await _auth.signOut();
          throw Exception('تم توقيف هذا الحساب');
        }
      }

      // Update online status in users collection
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('فشل في تسجيل الدخول: $e');
    }
  }

  // Get all veterinarians stream from users collection
  static Stream<List<Map<String, dynamic>>> getVeterinariansStream() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'veterinarian')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              // Map fields for compatibility
              'name': data['name'] ?? data['username'] ?? 'طبيب بيطري',
              'profilePhoto': data['profileImageUrl'] ?? data['profilePhoto'],
            };
          })
          .where((vet) => vet['isDeleted'] != true) // Filter out deleted veterinarians
          .toList();
    });
  }

  // Get all veterinarians for admin (including unverified) from users collection
  static Stream<List<Map<String, dynamic>>> getAllVeterinariansForAdmin() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'veterinarian')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              // Map fields for compatibility
              'name': data['name'] ?? data['username'] ?? 'طبيب بيطري',
              'profilePhoto': data['profileImageUrl'] ?? data['profilePhoto'],
            };
          })
          .where((vet) => vet['isDeleted'] != true) // Filter out deleted veterinarians
          .toList();
    });
  }

  // Create veterinarian from admin dashboard
  static Future<String> createVeterinarianFromAdmin({
    required String email,
    required String password,
    required String name,
    required String specialization,
    required String experience,
    required String phone,
    String? license,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create veterinarian profile in users collection with all veterinarian data
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': name,
        'name': name, // Also store as name for compatibility
        'phoneNumber': phone,
        'phone': phone, // Also store as phone for compatibility
        'specialization': specialization,
        'experience': experience,
        'license': license ?? '',
        'isOnline': false,
        'isActive': true,
        'rating': 0.0,
        'totalRatings': 0,
        'isVerified': true,
        'userType': 'veterinarian', // Flag to identify veterinarian
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'joinDate': DateTime.now().toIso8601String(),
      });

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      return uid;
    } catch (e) {
      throw Exception('فشل في إنشاء حساب الطبيب البيطري: $e');
    }
  }

  // Update veterinarian in users collection
  static Future<void> updateVeterinarian({
    required String vetId,
    required String name,
    required String email,
    required String specialization,
    required String experience,
    required String phone,
    String? license,
  }) async {
    try {
      await _firestore.collection('users').doc(vetId).update({
        'name': name,
        'username': name, // Also update username
        'email': email,
        'specialization': specialization,
        'experience': experience,
        'phone': phone,
        'phoneNumber': phone, // Also update phoneNumber
        if (license != null) 'license': license,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث بيانات الطبيب البيطري: $e');
    }
  }

  // Toggle veterinarian active status in users collection
  static Future<void> toggleVeterinarianStatus(String vetId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(vetId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تغيير حالة الطبيب البيطري: $e');
    }
  }

  // Delete veterinarian (mark as deleted in users collection)
  static Future<void> deleteVeterinarian(String vetId) async {
    try {
      // Mark as deleted instead of actually deleting
      await _firestore.collection('users').doc(vetId).update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Note: Firebase Auth user deletion requires admin SDK or the user to be signed in
      // For production, you should use Firebase Admin SDK or Cloud Functions
    } catch (e) {
      throw Exception('فشل في حذف الطبيب البيطري: $e');
    }
  }

  // Get veterinarian by ID from users collection
  static Future<Map<String, dynamic>?> getVeterinarianById(String vetId) async {
    try {
      final doc = await _firestore.collection('users').doc(vetId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Check if user is a veterinarian
        if (data['userType'] == 'veterinarian') {
          return {
            'id': doc.id,
            ...data,
            // Map fields for compatibility
            'name': data['name'] ?? data['username'] ?? 'طبيب بيطري',
            'profilePhoto': data['profileImageUrl'] ?? data['profilePhoto'],
          };
        }
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات الطبيب البيطري: $e');
    }
  }

  // Get veterinarian chats (for veterinarian dashboard)
  static Stream<List<Map<String, dynamic>>> getVeterinarianChatsStream(String vetId) {
    try {
      return _firestore
          .collection('veterinary_chats')
          .where('participants', arrayContains: vetId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['chatId'] = doc.id;
          return data;
        }).toList();
      }).handleError((error) {
        print('Error loading veterinarian chats: $error');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      print('Error in getVeterinarianChatsStream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Update veterinarian online status in users collection
  static Future<void> updateOnlineStatus(String vetId, bool isOnline) async {
    await _firestore.collection('users').doc(vetId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Update veterinarian profile
  static Future<void> updateVeterinarianProfile({
    required String vetId,
    String? name,
    String? specialization,
    String? experience,
    String? phone,
    String? profileImage,
    String? bio,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updateData['name'] = name;
      updateData['username'] = name; // Also update username
    }
    if (specialization != null) updateData['specialization'] = specialization;
    if (experience != null) updateData['experience'] = experience;
    if (phone != null) {
      updateData['phone'] = phone;
      updateData['phoneNumber'] = phone; // Also update phoneNumber
    }
    if (profileImage != null) {
      updateData['profileImage'] = profileImage;
      updateData['profileImageUrl'] = profileImage; // Also update profileImageUrl
      updateData['profilePhoto'] = profileImage; // Also update profilePhoto for compatibility
    }
    if (bio != null) updateData['bio'] = bio;

    await _firestore.collection('users').doc(vetId).update(updateData);
  }

  // Check if current user is veterinarian from users collection
  static Future<bool> isCurrentUserVeterinarian() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['userType'] == 'veterinarian';
    }
    return false;
  }

  // Get current veterinarian data
  static Future<Map<String, dynamic>?> getCurrentVeterinarian() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await getVeterinarianById(user.uid);
  }

  // Sign out veterinarian
  static Future<void> signOutVeterinarian() async {
    final user = _auth.currentUser;
    if (user != null) {
      await updateOnlineStatus(user.uid, false);
    }
    await _auth.signOut();
  }
} 