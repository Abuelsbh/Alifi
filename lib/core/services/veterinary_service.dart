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
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
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