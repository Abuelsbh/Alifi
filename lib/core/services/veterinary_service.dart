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

      // Create veterinarian profile in Firestore
      await _firestore.collection('veterinarians').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'specialization': specialization,
        'experience': experience,
        'phone': phone,
        'profileImage': profileImage,
        'bio': bio,
        'isOnline': false,
        'rating': 0.0,
        'totalRatings': 0,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userType': 'veterinarian',
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

      // Check if user is a veterinarian
      final vetDoc = await _firestore
          .collection('veterinarians')
          .doc(userCredential.user!.uid)
          .get();

      if (!vetDoc.exists) {
        await _auth.signOut();
        throw Exception('هذا الحساب ليس حساب طبيب بيطري');
      }

      // Check if veterinarian is deleted or inactive
      final vetData = vetDoc.data();
      if (vetData != null) {
        // Check if veterinarian is deleted
        if (vetData['isDeleted'] == true) {
          await _auth.signOut();
          throw Exception('تم حذف هذا الحساب');
        }
        // Check if veterinarian is inactive
        if (vetData['isActive'] == false) {
          await _auth.signOut();
          throw Exception('تم توقيف هذا الحساب');
        }
      }

      // Update online status
      await _firestore
          .collection('veterinarians')
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

  // Get all veterinarians stream
  static Stream<List<Map<String, dynamic>>> getVeterinariansStream() {
    return _firestore
        .collection('veterinarians')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((vet) => vet['isDeleted'] != true) // Filter out deleted veterinarians
          .toList();
    });
  }

  // Get all veterinarians for admin (including unverified)
  static Stream<List<Map<String, dynamic>>> getAllVeterinariansForAdmin() {
    return _firestore
        .collection('veterinarians')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
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

      // Create veterinarian profile in Firestore
      await _firestore.collection('veterinarians').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'specialization': specialization,
        'experience': experience,
        'phone': phone,
        'license': license,
        'isOnline': false,
        'isActive': true,
        'rating': 0.0,
        'totalRatings': 0,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'joinDate': DateTime.now().toIso8601String(),
        'userType': 'veterinarian',
      });

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      return uid;
    } catch (e) {
      throw Exception('فشل في إنشاء حساب الطبيب البيطري: $e');
    }
  }

  // Update veterinarian
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
      await _firestore.collection('veterinarians').doc(vetId).update({
        'name': name,
        'email': email,
        'specialization': specialization,
        'experience': experience,
        'phone': phone,
        'license': license,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث بيانات الطبيب البيطري: $e');
    }
  }

  // Toggle veterinarian active status
  static Future<void> toggleVeterinarianStatus(String vetId, bool isActive) async {
    try {
      await _firestore.collection('veterinarians').doc(vetId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تغيير حالة الطبيب البيطري: $e');
    }
  }

  // Delete veterinarian
  static Future<void> deleteVeterinarian(String vetId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('veterinarians').doc(vetId).delete();
      
      // Note: Firebase Auth user deletion requires admin SDK or the user to be signed in
      // For production, you should use Firebase Admin SDK or Cloud Functions
    } catch (e) {
      throw Exception('فشل في حذف الطبيب البيطري: $e');
    }
  }

  // Get veterinarian by ID
  static Future<Map<String, dynamic>?> getVeterinarianById(String vetId) async {
    try {
      final doc = await _firestore.collection('veterinarians').doc(vetId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
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

  // Update veterinarian online status
  static Future<void> updateOnlineStatus(String vetId, bool isOnline) async {
    await _firestore.collection('veterinarians').doc(vetId).update({
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

    if (name != null) updateData['name'] = name;
    if (specialization != null) updateData['specialization'] = specialization;
    if (experience != null) updateData['experience'] = experience;
    if (phone != null) updateData['phone'] = phone;
    if (profileImage != null) updateData['profileImage'] = profileImage;
    if (bio != null) updateData['bio'] = bio;

    await _firestore.collection('veterinarians').doc(vetId).update(updateData);
  }

  // Check if current user is veterinarian
  static Future<bool> isCurrentUserVeterinarian() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('veterinarians').doc(user.uid).get();
    return doc.exists;
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